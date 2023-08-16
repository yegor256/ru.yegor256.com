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
      start = Time.now
      total = 0
      site.posts.docs.each do |doc|
        pstart = Time.now
        txt = "eng-txt/#{doc.basename.gsub(/\.md$/, '-eng.txt')}"
        text = translate(doc.content, txt)
        yaml = "---\nlayout: eng\n---\n\n#{text}"
        path = "eng/#{doc.basename.gsub(/\.md$/, '-eng.md')}"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, yaml)
        site.pages << Page.new(site, site.source, File.dirname(path), File.basename(path))
        FileUtils.mkdir_p(File.dirname(txt))
        File.write(txt, text)
        site.static_files << StaticFile.new(site, site.source, File.dirname(txt), File.basename(txt))
        puts "Translated #{doc.basename} to English in #{(Time.now - pstart).round(2)}s"
        total += 1
      end
      puts "#{total} English pages generated in #{(Time.now - start).round(2)}s"
    end

    def translate(rus, txt)
      secrets = File.expand_path('~/secrets.yml')
      key = File.exist?(secrets) ? YAML.safe_load(File.open(secrets))['openai_api_key'] : nil
      if key.nil?
        puts "OpenAI key is not available, can't translate #{rus.split.count} Russian words"
        rus
      elsif Net::HTTP.get_response("https://ru.yegor256.com/#{txt}").is_a?(Net::HTTPSuccess)
        puts "OpenAI key is not available, can't translate #{rus.split.count} Russian words"
      else
        gpt(OpenAI::Client.new(access_token: key), rus)
      end
    end

    def gpt(client, rus)
      model = 'gpt-3.5-turbo'
      rus.split(/\n{2,}/).compact.map do |par|
        par.gsub!("\n", ' ')
        par.gsub!(/\s{2,}/, ' ')
        next unless par =~ /^[А-Я]/
        par = Redcarpet::Markdown.new(Strip).render(par)
        if par.length >= 32
          t = nil
          begin
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
            t = response.dig('choices', 0, 'message', 'content')
          rescue StandardError
            retry
          end
          if t.nil?
            puts "Failed to translate #{par.split.count} Russian words :("
            'FAILED TO TRANSLATE THIS PARAGRAPH'
          else
            puts "Translated #{par.split.count} words to #{t.split.count} English words through #{model}"
            t
          end
        else
          puts "Not translating this, b/c too short: \"#{par}\""
          par
        end
      end.join("\n\n").gsub(/\n{2,}/, "\n\n").strip
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
