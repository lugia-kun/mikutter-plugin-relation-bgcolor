# -*- mode: ruby; coding: utf-8; -*-

Plugin.create :relation_color do
  settings("関係背景色") do
    settings("関係背景色") do
      color("フォローしている皆々様", :following_color)
      color("フォローしていない皆々様", :unfollowing_color)
      color("フォローされている皆々様", :followed_by_color)
      color("フォローされていない皆々様", :unfollowed_by_color)
      input("アルファ値 (0〜255)", :color_alpha)
    end

    settings("API 調整") do
      boolean("新規取得をしない", :rel_color_new)
      input("API 下限値", :api_lowest)
    end

    about("about",
          {
            :name => "mikutter + extended color plugin",
            :version => "1.0",
            :comments =>
"色はミックスされるよ。
このプラグインは API を大量に消費するです。
最悪起動直後はツイートできないなんてことも…。",
            :copyright => "Copyright (C) 2012 Hajime Yoshimori",
            :authors => ["@LugiaKun"]
          })
  end

  def mix (ac, bc)
    if UserConfig[:color_alpha] == ""
      UserConfig[:color_alpha] = "20"
    end
    a = UserConfig[:color_alpha].to_i
    if (a < 0) then
      return ac
    end
    if (a > 255) then
      return bc
    end
    r = ac[0] * (255 - a) / 256 + bc[0] * a / 256
    g = ac[1] * (255 - a) / 256 + bc[1] * a / 256
    b = ac[2] * (255 - a) / 256 + bc[2] * a / 256
    return [r, g, b]
  end

  filter_message_background_color do |message,color|
    if ! color
      color = [65535, 65535, 65535]
    end
    u = message.to_message.user
    if ! @udb.key? u[:id] then
      if UserConfig[:rel_color_new] == false then
        s = Post.primary
        s.friendship(target_id: u[:id],
                     source_id: s.user_obj[:id]).next { |rel|
          @udb[u[:id]] = {
            :followed_by => rel[:followed_by],
            :following   => rel[:following]
          }
          if @udb[u[:id]][:followed_by] then
            color = mix(color, UserConfig[:followed_by_color])
          else
            color = mix(color, UserConfig[:unfollowed_by_color])
          end
          if @udb[u[:id]][:following] then
            color = mix(color, UserConfig[:following_color])
          else
            color = mix(color, UserConfig[:unfollowing_color])
          end
        }.terminate
      else
        puts u[:id]
      end
    else
      if @udb[u[:id]][:followed_by] then
        color = mix(color, UserConfig[:followed_by_color])
      else
        color = mix(color, UserConfig[:unfollowed_by_color])
      end
      if @udb[u[:id]][:following] then
        color = mix(color, UserConfig[:following_color])
      else
        color = mix(color, UserConfig[:unfollowing_color])
      end
    end
    [message, color]
  end

  onboot do
    @udb = Hash.new
  end
end
