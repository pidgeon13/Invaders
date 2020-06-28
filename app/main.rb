$gtk.reset

$screen_width = 1280
$screen_height = 720
$game_width = 600

$game_left_extent = ($screen_width-$game_width)/2
$game_right_extent=$game_left_extent + $game_width

class Bullet
  attr_reader :pos_x
  attr_reader :pos_y
  attr_reader :needs_deleting
  def initialize pos_x, pos_y, dir
    @pos_x = pos_x
    @pos_y = pos_y
    @dir = dir
    @size = 5
    @needs_deleting = false
  end
  def move
    @pos_y += (@dir*10)
  end
  def render
    $solids << [@pos_x, @pos_y, @size, @size, 255, 0, 255]
  end
  def remove
    @needs_deleting = true
  end
end

class Player
  attr_reader :pos_x
  attr_reader :pos_y
  def initialize size
    @size = size
    @pos_x = ($screen_width - @size) / 2
    @pos_y = 10
    @speed = 8
    @cooldown = 0
    @max_cooldown = 30
  end
  def update
    if(@cooldown > 0)
      @cooldown -= 1
    end
  end
  def move_left
    if(@pos_x >= $game_left_extent + @speed)
      @pos_x-=@speed
    end
  end
  def move_right
    if(@pos_x <= $game_right_extent - @size - @speed)
      @pos_x+=@speed
    end
  end
  def fire_bullet
    @cooldown=@max_cooldown
    $sounds << "audio/flaunch.wav"
    return Bullet.new @pos_x + (@size/2), @pos_y +@size, 1
  end
  def can_fire
    return @cooldown <= 0
  end
  def render
    if(!@needs_deleting)
      $sprites << [@pos_x, @pos_y, @size*1.2, @size*1.9, "sprites/kestral.png"]
    end
  end
end

class Enemy_Grid
  attr_reader :pos_y
  def initialize number_x, number_y, left = $game_left_extent, top = $screen_height, size_x = 30
    @number_x = number_x
    @number_y = number_y
    @size_x = size_x
    @size_y = size_x*(337/259)
    @pos_x = left
    @pos_y = top - @number_y * @size_y
    @grid = Array.new(@number_x) {Array.new(@number_y, 1)}
    @velocity = 20
    @vertical_jump = @size_y/2
  end
  def render
    for i in 0..@grid.length-1
      column=@grid[i]
      for j in 0..column.length-1
        if(column[j]!=0)
          $sprites << [@pos_x+i*@size_x, @pos_y + j*@size_y, @size_x, @size_y, "sprites/mantis_crop.png"]
        end
      end
    end
  end
  def length
    return @size_x*@number_x
  end
  def height
    return @size_x*@number_y
  end
  def needs_to_move_down
    moving_right = @velocity > 0
    if moving_right
      #Check if we've hit the right side of the board
      return @pos_x + length >= $game_right_extent + @velocity
    else
      #Check if we've hit the left side of the board
      return @pos_x <= $game_left_extent - @velocity
    end
  end
  def move
    if needs_to_move_down 
      @pos_y-= @vertical_jump
      @velocity = -@velocity
    else
      @pos_x += @velocity
    end
  end
  def hitting bullet
    distance_x = bullet.pos_x - @pos_x
    distance_y = bullet.pos_y - @pos_y
    if(distance_x < 0 || distance_y < 0)
      return false
    end
    index_x = (distance_x/@size_x).floor
    index_y = (distance_y/@size_y).floor
    if(index_x >= @number_x || index_y >= @number_y)
      return false
    end
    hitting = false
    if(@grid[index_x][index_y] !=0)
      hitting = true
      @grid[index_x][index_y] = 0
    end
    return hitting
  end
  def is_empty column
    return column.all? {|value| value == 0}
  end
  def clean_columns
    indexes_to_remove = []
    possible_indexes_to_remove = []
    all_empty_so_far = true
    for i in 0..@grid.length - 1
      column = @grid[i]
      if(is_empty column)
        if(all_empty_so_far)
          indexes_to_remove << i
        else
          possible_indexes_to_remove << i
        end
      else
        all_empty_so_far = false
        possible_indexes_to_remove = []
      end
    end
    if all_empty_so_far
      @grid= []
    else
      pre_columns_removed = indexes_to_remove.length
      indexes_to_remove += possible_indexes_to_remove
      indexes_to_remove.reverse_each do |index|
        @grid.delete_at index
      end
      @number_x = @grid.length
      @pos_x += pre_columns_removed*@size_x
    end
  end
  def number_leading_zeros column
    zeros=0
    column.each do |value|
      if value !=0
        break
      end
      zeros+=1
    end
    return zeros
  end
  def clean_rows
    leading_zeros = @grid.map { |col| number_leading_zeros col}
    rows_to_clean = leading_zeros.min
    @grid.each do |column|
      column.slice! 0, rows_to_clean
    end
    @number_y -= rows_to_clean
    @pos_y += rows_to_clean*@size_y
  end
  def clean
    clean_columns
    clean_rows
  end
end

class InvadersGame
  def initialize (args)
    @player = Player.new 30
    @bullets = []
    @enemies = Enemy_Grid.new 15, 4
    @death_point = 100
    @game_over = false
  end
  def render_background
    $solids << [0,0, $screen_width, $screen_height, 30, 30, 30]
    $solids << [$game_left_extent, 0, $game_width, $screen_height]
    $lines << [$game_left_extent, @death_point, $game_right_extent, @death_point, 255,255,255]
  end
  def update_bullets
    if $inputs.keyboard.key_down.space || $inputs.keyboard.key_held.space
      if @player.can_fire
        @bullets << @player.fire_bullet
      end
    end
    @bullets.delete_if {|bullet| bullet.pos_y >= $screen_height || bullet.needs_deleting}
    @bullets.each do |bullet|
      bullet.move
      if(@enemies.hitting bullet)
        bullet.remove
      end
      bullet.render
    end
  end
  def update_player
    if ($inputs.keyboard.key_held.left)
      @player.move_left
    end
    if ($inputs.keyboard.key_held.right)
      @player.move_right
    end
    @player.update
    @player.render
  end
  def render_game_over
    $labels << [$game_left_extent+$game_width/2,3*$screen_height/4, "Game Over", 10, 1, 255, 255, 255]
    $labels << [$game_left_extent+$game_width/2,5*$screen_height/8, "Press the enter key to play again", 4, 1, 255, 255, 255] 
  end
  def restart_game_if_prompted
    if $inputs.keyboard.key_down.enter
      @bullets = []
      @enemies = Enemy_Grid.new 15, 4
      @game_over=false
    end
  end
  def tick
    render_background
    if(@game_over)
      render_game_over
      restart_game_if_prompted
    else
      update_player
      update_bullets
      @enemies.clean
      @enemies.move
      @enemies.render
      if(@enemies.pos_y <= @death_point)
        @game_over=true
      end
    end
  end
end

def tick args
  $inputs = args.inputs
  $solids = args.outputs.solids
  $sprites = args.outputs.sprites
  $sounds = args.outputs.sounds
  $lines = args.outputs.lines
  $labels = args.outputs.labels
  args.state.game ||= InvadersGame.new args
  args.state.game.tick
end
