#= Post
#
# Represents a post in the blog
class Post < ApplicationRecord
  validates :title, :body, presence: true
end
