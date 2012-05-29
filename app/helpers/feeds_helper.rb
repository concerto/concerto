module FeedsHelper

  # Generate a depth first ordered tree.
  def dfs_tree(roots = Feed.roots, break_at = nil)
    nodes = []
    roots.each do |node|
      nodes += [node] unless (node == break_at)      
      nodes += node.descendants unless (node.descendants.empty? || node == break_at)
    end
    if !break_at.nil?
      rejectable = break_at.descendants
      nodes = nodes.reject{|n| rejectable.include?(n) || n == break_at}
    end
    nodes
  end

end
