class FS
  @@inode_count = 0

  attr_accessor :name, :inode

  def initialize(name)
    @@inode_count += 1
    @name = name
    @inode = @@inode_count
  end

  def update_inode
    @@inode_count += 1
    @inode = @@inode_count
  end

  # for real copy
  def initialize_copy(obj)
    @@inode_count += 1
    @name = obj.name.dup if obj.name
    @inode = @@inode_count
  end
end

class Branch < FS
  attr_accessor :branches, :parent

  def initialize(name = nil)
    super(name)
    @branches = Hash.new
    @parent = nil
  end

  def mkdir(name)
    @branches[name] = Branch.new(name)
    @branches[name].parent = self
  end

  def touch(name, data)
    @branches[name] = Reaf.new(name, data)
  end

  def rm
    fun = Proc.new{self.parent.branches.delete(self.name)}
    cow(fun)
  end

  def cow(fun)
    new_self = self.dup
    top = new_self.copy
    fun.call

    #commit
    top.parent.branches[top.name] = top
  end

  def copy
    if self.parent.name != ROOT
      self.parent = self.parent.dup
      self.parent.branches[self.name] = self
      top = self.parent.copy
    else
      top = self
    end
    top
  end

  def show_branch(path = "/")
    path += self.name + "/" if self.name
    puts path
    puts self.inode
    if self.branches.size > 0
      self.show_each_branch(path)
    end
  end

  def show_each_branch(path)
    self.branches.each_value do |branch|
      if branch.class == Branch
        branch.show_branch(path)
      else
        data = path + branch.name + " = " + branch.data if branch.name && branch.data
        puts data
        puts branch.inode
      end
    end
  end

  private

  def set_parents(obj)
    obj.branches.each_values do |v|
      v.parent = obj
    end
  end

  # for real copy
  def initialize_copy(obj)
    super(obj)
  end
end

class Reaf < FS
  attr_accessor :data

  def initialize(name = nil, data = nil)
    super(name)
    @data = data
  end

  # for real copy
  def initialize_copy(obj)
    super(obj)
    @data = obj.data.dup if obj.data
  end
end

ROOT = "root"

root = Branch.new(ROOT)
root.mkdir("usr")
root.mkdir("bin")
root.branches["usr"].mkdir("local")
root.branches["usr"].branches["local"].mkdir("bin")
root.branches["usr"].branches["local"].touch("test.txt", "This is text.")

puts "---start---"
root.show_branch
puts "---cow(update)---"
root.branches["usr"].branches["local"].branches["bin"].rm
root.show_branch

#
# debug
#
puts "\n---debug---"
p root.branches["usr"].branches["local"].branches["test.txt"].data
p root.branches["usr"].branches["local"].inode
copy = root.dup

# check object_id
puts copy.name.object_id
puts root.name.object_id
puts root.branches.object_id
puts copy.branches.object_id

# check real copy
puts copy.inode
copy.inode = 9
puts root.inode
puts copy.inode
