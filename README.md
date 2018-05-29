# Icalia Docker Praxis

This is a collection of examples and notes about our Docker practices at Icalia Labs

## About Mentors

We recommend you to identify the available platform mentors in the team so whenever you find a
problem regarding Docker and the development technology you're using, you know the right person to
help you with your issue:

| Expertise         | Guru | Contact Email      |
| ----------------- | ---- | ------------------ |
| All Things Docker | Vov  | vov@icalialabs.com |
| Ruby + Rails      | Vov  | vov@icalialabs.com |
| Elixir            | ???  | ???@icalialabs.com |
| Python            | ???  | ???@icalialabs.com |
| Java              | ???  | ???@icalialabs.com |
| PHP               | ???  | ???@icalialabs.com |
| ReactJS + Docker  | ???  | ???@icalialabs.com |
| EmberJS + Docker  | Vov  | vov@icalialabs.com |

## About our team's workstation OS diversity

We do want our team members to use their operative system of choice (Linux, MacOS or Windows*),
whenever it is possible. Each team member is responsible to notify the appropiate mentor about any
problem found. The following considerations *must* be followed to allow collaboration from the rest
of our team members, regardless of their workstation OS of choice:

### Docker for Mac

#### General Considerations

* ENSURE THE `**/*.DS_Store` LINE IS INCLUDED IN THE `.gitignore` FILE! (and any other ignore files)

### Docker for Linux

#### The File Permissions Issue

We run our development container processes as `root` in our projects (See
[Why we run development container processes as root](#not-yet-written)). This practice poses no
problems when using Docker for Mac/Windows, as the shared files in the host are replicated to the
guest Docker VM without file owner/group data. But that's not the case for our teammates using
Docker for Linux, so when generating files inside a container (i.e. when using the `rails generate`
command), the generated files belonged to the host's `root` user, preventing them from editing those
files with their IDE's, and making a poor development experience with Docker.

The best strategy we've found to work around this is to "re-map" the Docker container's `root` user
& group IDs to the host's developer user & group IDs, using a Docker daemon isolation feature (See
[ability to remap subordinate user and group ids](https://docs.docker.com/engine/security/userns-remap/#about-remapping-and-subordinate-user-and-group-ids)
for more info)

These are the steps to configure your Docker daemon this way:

1. Prune all your current Docker images, containers and volumes:

    Once the remap configuration is active, you'll no longer be able to access (via `docker`)
    your existing images, containers and volumes, adding up to your workstation's
    "unreclaimable" disk space. It's better to prune all of that out:

    ```bash
    docker system prune --all --force --volumes
    ```

2. Create or Replace the `/etc/subuid` and `/etc/subgid` files:

    These files define the mapping as an offset between the host `uid`/`gid` and the container
    processes' `uid`/`gid`.

    ```bash
    echo "$(id -un):$(id -u):65536" | sudo tee /etc/subuid
    # Example Output:
    # testuser:1000:65536

    echo "$(id -gn):$(id -g):65536" | sudo tee /etc/subgid
    # Example Output:
    # testuser:1000:65536
    ```

    The entries that will be saved in these files mean that for the current user, the
    subprocess' `uid`/`gid` will be an offset of the host's `uid`/`gid`, and only applies for
    the following 65536 `uid`s/`gid`s:

      * The container's `root` user, having the `0` uid will be remapped to the host's uid of
        the current user.
      * If there's some other user in the container having a `500` uid, it will be remapped
        to the host's `1500` uid, while the container user having the `501` uid will be remapped to the host's `1501` uid.

3. Now, you'll need to configure your host's Docker engine to apply the remapping:

    ```bash
    echo "{\n  \"userns-remap\" : \"$(id -un)\"\n}" | sudo tee /etc/docker/daemon.json
    # Example Output:
    # {
    #   "userns-remap" : "testuser"
    # }
    ```

4. Be sure to restart your Docker daemon:

    ```bash
    sudo service docker restart
    ```

5. Finally, test that the files generated within the container have the correct owner on
the host (your user):

    ```bash
    # Run it from within your desktop, bind-mounting it into the container:
    cd ~/Desktop && docker run --rm -ti -v $(pwd):/my-desktop -w /my-desktop alpine ash

    # Once inside the container - be sure no 'permission denied' error appears:
    echo "TEST" > test.txt

    # Exit the container:
    exit

    # Once your'e back to your host, check that the created file belongs to your user & group:
    ls -lah
    ```

If something here didn't go as planned, please check:

* Your user id and group id matches those on the `/etc/subuid` and `/etc/subgid`.
* Your'e pointing the `"userns-remap"` to the corresponding entry at the `/etc/docker/daemon.json`.
* You have restarted the Docker daemon after configuring the user namespace remapping.

If your'e still having problems, ask for help to corresponding mentor (@vovimayhem).

### Docker for Windows

#### Important Stuff

These are the common problems we've encountered when using Docker for Windows. All of these are not with Docker for Windows itslef, but rather some gotchas found when working with diverse environments (Teams working with Windows and Linux):

 * Make sure you are not using "automatic line-ending conversions" [See this one](http://willi.am/blog/2016/08/11/docker-for-windows-dealing-with-windows-line-endings/)
#### General Considerations

* Docker for Windows will only work for Windows 10 Pro, which contains the Hyper-V hypervisor.
