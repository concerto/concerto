module FeedsHelper

  # Generate a depth first ordered tree.
  def dfs_tree(roots = Feed.roots)
    nodes = []
    roots.each do |node|
      nodes += [node]
      nodes += node.descendants unless node.descendants.empty?
    end
    nodes
  end

end
