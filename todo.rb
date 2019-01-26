#!/usr/bin/env ruby
# coding: utf-8
# By Gregory 'kalidor' Charbonneau under the terms of WtfPLv2
# 12-13-2014

require 'yaml'
require 'optparse'

CONF = File.join(ENV["HOME"],".todo.yaml")

class String
  def colorize(color_code)
    # 31 = red
    # 32 = green
    # 33 = yellow
    "\e[#{color_code}m#{self}\e[0m"
  end
  def partial_colorize(limit=self.length, color_code)
    "\e[#{color_code}m#{self[0..limit]}\e[0m" + self[limit+1..-1]
  end
end

module Todo
  class Task
    def initialize(task_file=nil)
      load
    end

    def compute_color(v)
      color = 41
      case v
      when 0...25
        color = 41
      when 25...65
        color = 43
      when 65...100
        color = 42
      else # 100%
        color = 42
      end
      color
    end

    def load
      @index = {}
      (@tasks = {}; return) if not File.exists?(CONF)
      @tasks = YAML.load(File.read(CONF))
      @tasks.each_with_index{|kv, i|
        @index[kv.first] = i # weird, i know. logical it will be another way...
      }
    end

    def save
      File.open(CONF, 'w') {|f| f.write @tasks.to_yaml }
    end

    def delete(opts)
      id = opts['delete']
      res = @index.select{|t, i| i==id.to_i}
      if res
          res = res.keys.first
        if @tasks.keys.include?(res)
          @tasks.delete(res)
          @index.delete(res)
          save()
        end
      else
        puts "[!] Can't find index"
      end
      display_status(opts)
    end

    def display_status(opts)
      if @tasks.length == 0
        puts "[-] Empty TODO list"
        return
      end
      todo_tasks = @tasks.select{|k,v|
        (opts['all'])?(v <= 100):(v < 100)
      }
      diff = @tasks.size - todo_tasks.size
      (puts "[+] %d finished task(s) hidden" % diff) if diff > 0
      todo_tasks.map{|k,v|
        if opts['color']
          color_size = (v * (k.length+6)) / 100
          color = compute_color(v)
          puts "#{@index[k]}) " + ("#{k} (#{v}%) "+" " * color_size).partial_colorize(color_size, color)
        else
          puts "#{@index[k]}) " + "#{k} (#{v}%) "
        end
        }
      # save in the same format as YAML::load
      Hash[@tasks.map{|k,v| [k, v]}]
    end

    def update(opts)
      task = opts['update']
      (puts "[-] Miss integer value"; return) if not task.length >= 2
      if task.first =~ /^\d+$/
        id = task.first.to_i
        (puts "[!] Can't find index") if not @index.has_value?(id)
        @tasks[@index.select{|k,v| v == id}.keys.first] = task[1].to_i
      else
        (puts "[-] Can't find index Creating new entry"; opts['new']=opts['update']; new(opts); return) if @tasks.has_key?(task.first)
        @tasks[task.first] = task[1].to_i
      end
      save()
      display_status(opts)
    end

    def new(opts)
      (puts "[-] Miss integer value"; return) if not opts['new'].length >= 2
      @tasks[opts['new'].first] = opts['new'][1].to_i
      save()
      load()
      display_status(opts)
    end
  end
end

if $0 == __FILE__
  opts = {
    'pull' => nil,
    'push' => nil,
    'update' => nil,
    'all' => nil,
    'done' => nil,
    'new' => nil,
    'delete' => nil,
    'color' => nil
  }
  @options = OptionParser.new
  @options.separator ""
  #todo
  #@options.on('-p', '--pull', 'Pull') { opts['pull'] = true }
  #@options.on('-P', '--push', 'Push') { opts['push'] = true }
  @options.on('-c', '--color', 'Color') { opts['color'] = true}
  @options.on('-s', '--show', 'Show all tasks (complete tasks)') { opts['all'] = true }
  @options.on('-u', '--update task_num,level', Array, 'Update task using id') {|opt| opts['update'] = opt }
  @options.on('-a', '--add task,level', Array, 'Adding a task to todo') {|opt| opts['new'] = opt }
  @options.on('-d', '--del task', 'Delete a task') {|opt| opts['delete'] = opt }
  begin
    @options.parse(ARGV)
  rescue OptionParser::MissingArgument => e
    puts "[!] %s" % e.message
    exit
  end

  task = Todo::Task.new("task.yaml")
  if opts['new']
    task.new(opts)
  elsif opts['delete']
    task.delete(opts)
  elsif opts['update']
    task.update(opts)
  else
    task.display_status(opts)
  end
end
