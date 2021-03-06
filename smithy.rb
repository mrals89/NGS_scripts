# This file includes code for an implementation of Smith Waterman, inspired by Vincent Chu
# https://gist.github.com/vincentchu
#
# In the current state, this alogrithm needs to be run interactively. 
# It should be initialized with two sequences of the string class.
# Currently, it can return a string representation of an alignment, and then 
#
# Usage: 
# sa=StringAlign.new(string_one, string_two)
# sa.score #returns score
# sa.alignment_inspect prints the full alignment, avoid if possible.



class Matrix
  
  IndexOverflow = Class.new(StandardError)
  
  attr_reader :dims, :nrows, :ncols
  
  def initialize(mm, nn)
    @dims  = [mm, nn]
    @nrows = mm
    @ncols = nn
    @m     = Array.new(mm)
 
    (1..mm).each {|i| @m[i-1] = Array.new(nn, 0)}
  end
  
  def inspect
    @m.inject("") do |str, row|
      str +=  row.collect {|v| sprintf("%5d", v)}.join(" ") + "\n"
    end
  end  
 
  def [](i, j)    
    raise IndexOverflow if ((i >= nrows) || (j >= ncols))
    
    @m[i][j]
  end
  
  def []=(i, j, k)
    raise IndexOverflow if ((i >= nrows) || (j >= ncols))
 
    @m[i][j] = k
  end
end
 
class StringAlign
 
  SCORE_INSERT =  -2
  SCORE_DELETE =  -2
  SCORE_MISS   = -1
  SCORE_MATCH  =  2
 
  attr_reader :str_a, :str_b, :str_a_arr, :str_b_arr, :m, :n, :mat, :config, :alignment, :score
 
  def initialize(stra, strb, opts = {})
    @str_a  = stra
    @str_b  = strb
    
    @str_a_arr = stra.unpack("U*")
    @str_b_arr = strb.unpack("U*")
    
    @m      = str_a.length + 1
    @n      = str_b.length + 1
    @mat    = Matrix.new(m, n)
    
    @config = opts
  end
 
  def align!
    iterate_over_cells!
    find_optimal_path
    
    return alignment
  end
  
  def alignment_inspect
    
    la = "... "
    lb = "... "
    
    alignment.each_with_index do |pos, i|
      next if (i == 0)
      
      case alignment[i-1][2]
        when :down
          la += [ str_a_arr[pos[0]-1] ].pack("U*")
          lb += "-"
        when :right
          la += "-"
          lb += [ str_b_arr[pos[1]-1] ].pack("U*")
        else
          la += [ str_a_arr[pos[0]-1] ].pack("U*")
          lb += [ str_b_arr[pos[1]-1] ].pack("U*")
      end
    end
    
    "#{la} ...\n#{lb} ..."    
  end
  
  private
  
  def find_optimal_path    
    @alignment = []    
    recurse_optimal_path(@i_max, @j_max)
 
    @alignment.reverse!
    @alignment.each_with_index do |pos, i|
      next_pos = alignment[i+1]
      next if next_pos.nil?
 
      del_i = next_pos[0] - pos[0]
      del_j = next_pos[1] - pos[1]
      direction = case (del_i + del_j)
        when 2
          :diagonal
        when 1
          (del_i > del_j) ? :down : :right
      end
 
      pos << direction
    end
  end
 
  def recurse_optimal_path(i_curr, j_curr)    
    @alignment << [i_curr, j_curr]
    
    values = [
      mat[i_curr-1, j_curr-1],
      mat[i_curr-1, j_curr],
      mat[i_curr  , j_curr-1]
    ]
    
    ii, jj = case values.index(values.max)
      when 0
        [i_curr-1, j_curr-1]
      when 1
        [i_curr-1, j_curr  ]
      when 2
        [i_curr  , j_curr-1]
    end    
    
    if (mat[i_curr, j_curr] == 0)
      return
    else
      return recurse_optimal_path(ii, jj)
    end
  end
  
  def iterate_over_cells!
    
    @score = -1
    @i_max = 0
    @j_max = 0
    
    (2..m).each do |i|
      (2..n).each do |j|
        assign_cell(i-1, j-1)
      end
    end
  end
  
  def assign_cell(i, j)
    score = (str_a_arr[i-1] == str_b_arr[j-1]) ? SCORE_MATCH : SCORE_MISS      
 
    value = [
      0,
      mat[i-1, j-1] + score,
      mat[i-1, j] + SCORE_DELETE,
      mat[i, j-1] + SCORE_INSERT      
    ].max
    
    if (value >= @score)
      @score = value
      @i_max = i
      @j_max = j
    end
    
    mat[i,j] = value
  end
end
