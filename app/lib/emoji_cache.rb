class EmojiCache
  def initialize(team)
    @team = team
    @api_checked = false
  end

  def read(*names)
    # If Redis hasn't been configured as the cache store, always hit the API
    unless Rails.cache.is_a?(ActiveSupport::Cache::RedisCacheStore)
      return @team.api_client.emoji_list.emoji.slice(*names).compact
    end

    # Sometimes we just don't need to render any custom emoji :shrug:
    return {} if names.empty?

    # Otherwise, pull the requested emoji out of Redis and return them,
    # assuming we got results for all of the emoji
    emoji = redis.mapped_hmget(key, *names)
    return emoji if emoji.values.all? || @api_checked

    # If any names didn't have a result, we'll refresh our cache and use the
    # current API response to find our URLs.
    emoji = @team.api_client.emoji_list.emoji
    write(emoji)

    # Avoid a scenario where we keep hitting the API because we encountered
    # an :emoji: that just isn't actually an emoji
    @api_checked = true
    emoji.slice(*names)
  end

  def bust!
    redis.del(key)
  end

  private

  def redis
    Rails.cache.redis
  end

  def key
    @key ||= "teams:#{@team.slack_id}:emoji".freeze
  end

  def write(emoji)
    bust!
    redis.hset(key, emoji)
  end
end
