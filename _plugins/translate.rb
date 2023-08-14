# frozen_string_literal: true

# Copyright (c) 2014-2023 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so. The Software doesn't include files with .md extension.
# That files you are not allowed to copy, distribute, modify, publish, or sell.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'openai'
require 'redcarpet'

# Jekyll module
module Jekyll
  # The class
  class EngGenerator < Generator
    priority :low
    def generate(site)
      secrets = File.expand_path('~/secrets.yml')
      key = File.exist?(secrets) ? YAML.safe_load(File.open(secrets))['openai_api_key'] : nil
      client = OpenAI::Client.new(
        access_token: key,
        request_timeout: 600
      )
      model = 'gpt-3.5-turbo'
      start = Time.now
      total = 0
      site.posts.docs.each do |doc|
        pstart = Time.now
        text = doc.content.split(/\n{2,}/).compact.map do |par|
          par.gsub!("\n", ' ')
          par.gsub!(/\s{2,}/, ' ')
          next unless par =~ /^[А-Я]/
          par = Redcarpet::Markdown.new(Strip).render(par)
          if key.nil?
            puts "OpenAI key is not available, can't translate #{par.split.count} Russian words"
            par
          elsif par.length >= 32
            t = begin
              response = client.chat(
                parameters: {
                  model: model,
                  messages: [{
                    role: 'user',
                    content: "Пожалуйста, переведи этот параграф на английский язык:\n\n#{par}"
                  }],
                  temperature: 0.7
                }
              )
              response.dig('choices', 0, 'message', 'content')
            rescue Net::ReadTimeout
              retry
            end
            puts "Translated #{par.split.count} Russian words to #{t.split.count} English words through #{model}"
            t
          else
            puts "Not translating this, b/c too short: \"#{par}\""
            par
          end
        end.join("\n\n").gsub(/\n{2,}/, "\n\n").strip
        yaml = "---\nlayout: eng\nmodel: #{model}\n---\n\n#{text}"
        path = "eng/#{doc.basename.gsub(/\.md$/, '-eng.md')}"
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir)
        File.write(path, yaml)
        site.pages << Page.new(site, site.source, dir, File.basename(path))
        puts "Translated #{doc.basename} to English in #{(Time.now - pstart).round(2)}s"
        total += 1
      end
      puts "#{total} English pages generated in #{(Time.now - start).round(2)}s"
    end
  end

  # Markdown to pain text.
  class Strip < Redcarpet::Render::Base
    [
      # block-level calls
      :block_code, :block_quote,
      :block_html, :list, :list_item,
      # span-level calls
      :autolink, :codespan, :double_emphasis,
      :emphasis, :underline, :raw_html,
      :triple_emphasis, :strikethrough,
      :superscript, :highlight, :quote,
      # footnotes
      :footnotes, :footnote_def, :footnote_ref,
      # low level rendering
      :entity, :normal_text
    ].each do |method|
      define_method method do |*args|
        args.first
      end
    end

    def paragraph(text)
      text
    end

    def link(_link, _title, content)
      content
    end
  end
end
