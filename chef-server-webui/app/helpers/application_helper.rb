require 'chef/mixin/deep_merge'

module Merb
  module ChefServerWebui
    module ApplicationHelper
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def image_path(*segments)
        public_path_for(:image, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def javascript_path(*segments)
        public_path_for(:javascript, *segments)
      end
      
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def stylesheet_path(*segments)
        public_path_for(:stylesheet, *segments)
      end
      
      # Construct a path relative to the public directory
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path relative to the public directory, with added segments.
      def public_path_for(type, *segments)
        ::ChefServerWebui.public_path_for(type, *segments)
      end
      
      # Construct an app-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the host application, with added segments.
      def app_path_for(type, *segments)
        ::ChefServerWebui.app_path_for(type, *segments)
      end
      
      # Construct a slice-level path.
      # 
      # @param <Symbol> The type of component.
      # @param *segments<Array[#to_s]> Path segments to append.
      #
      # @return <String> 
      #  A path within the slice source (Gem), with added segments.
      def slice_path_for(type, *segments)
        ::ChefServerWebui.slice_path_for(type, *segments)
      end

      def build_tree(name, node, default={}, override={})
        node = Chef::Mixin::DeepMerge.merge(default, node)
        node = Chef::Mixin::DeepMerge.merge(node, override)
        html = "<table id='#{name}' class='tree table'>"
        html << "<tr><th class='first'>Attribute</th><th class='last'>Value</th></tr>"
        count = 0
        parent = 0
        append_tree(name, html, node, count, parent, override)
        html << "</table>"
        html
      end

      def append_tree(name, html, node, count, parent, override)
        node.sort{ |a,b| a[0] <=> b[0] }.each do |key, value|
          to_send = Array.new
          count += 1
          is_parent = false
          local_html = ""
          local_html << "<tr id='#{name}-#{count}' class='collapsed #{name}"
          if parent != 0
            local_html << " child-of-#{name}-#{parent}' style='display: none;'>"
          else
            local_html << "'>"
          end
          local_html << "<td class='table-key'><span toggle='#{name}-#{count}'/>#{key}</td>"
          case value
          when Hash
            is_parent = true 
            local_html << "<td></td>"
            p = count
            to_send << Proc.new { append_tree(name, html, value, count, p, override) }
          when Array
            is_parent = true 
            local_html << "<td></td>"
            as_hash = {}
            value.each_index { |i| as_hash[i] = value[i] }
            p = count
            to_send << Proc.new { append_tree(name, html, as_hash, count, p, override) }
          when String,Symbol
            local_html << "<td><div class='json-attr'>#{value}</div></td>"
          else
            local_html << "<td>#{JSON.pretty_generate(value)}</td>"
          end
          local_html << "</tr>"
          local_html.sub!(/class='collapsed/, 'class=\'collapsed parent') if is_parent
          local_html.sub!(/<span/, "<span class='expander'") if is_parent
          html << local_html
          to_send.each { |s| count = s.call }
          count += to_send.length
        end
        count
      end
      
      def syntax_highlight(code)
        converter = Syntax::Convertors::HTML.for_syntax "ruby"
        if File.exists?(code)
          converter.convert(File.read(code), false)
        else
          converter.convert(code, false)
        end
      end
      
      def get_file(uri)
        r = Chef::REST.new(Chef::Config[:chef_server_url])
        content = r.get_rest(uri)
        a = Tempfile.new("cookbook_temp_file")
        File.open(a.path, 'w'){|f| f.write(content)}
        path = a.path
        a.close
        path
      end
      
      def str_to_bool(str)
        str =~ /true/ ? true : false
      end
      
      #for showing search result
      def determine_name(type, object)
        if type == :node
          object.name.gsub(/\./, '_')
        elsif type == :role
          object.name
        else
          params[:id] 
        end 
      end 
      
      def get_databag_item_name(uri)
        uri.split("/").last
      end 

      # Recursively build a tree of lists.
      #def build_tree(node)
      #  list = "<dl>"
      #  list << "\n<!-- Beginning of Tree -->"
      #  walk = lambda do |key,value|
      #    case value
      #      when Hash, Array
      #        list << "\n<!-- Beginning of Enumerable obj -->"
      #        list << "\n<dt>#{key}</dt>"
      #        list << "<dd>"
      #        list << "\t<dl>\n"
      #        value.each(&walk)
      #        list << "\t</dl>\n"
      #        list << "</dd>"
      #        list << "\n<!-- End of Enumerable obj -->"
      #        
      #      else
      #        list << "\n<dt>#{key}</dt>"
      #        list << "<dd>#{value}</dd>"
      #    end
      #  end
      #  node.sort{ |a,b| a[0] <=> b[0] }.each(&walk)
      #  list << "</dl>"
      #end
      
    end
  end
end
