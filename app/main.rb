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
    @speed = 12
    @cooldown = 0
    @max_cooldown = 10
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
  def initialize number_x, number_y, left = $game_left_extent, top = $screen_height, size_x = 30
    @number_x = number_x
    @number_y = number_y
    @size_x = size_x
    @size_y = size_x*(337/259)
    @pos_x = left
    @pos_y = top - @number_y * @size_y
    @grid = Array.new(@number_x) {Array.new(@number_y, 1)}
    @velocity = 1
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
    puts index_x
    if(index_x >= @number_x || index_y >= @number_y)
      return false
    end
    hitting = false
    if(@grid[index_x][index_y] == 1)
      hitting = true
      @grid[index_x][index_y] = 0
    end
    return hitting
  end
end

class InvadersGame
  def initialize (args)
    @player = Player.new 30
    @bullets = []
    @enemies = Enemy_Grid.new 15, 4
  end
  def render_background
    $solids << [0,0, $screen_width, $screen_height, 30, 30, 30]
    $solids << [$game_left_extent, 0, $game_width, $screen_height]
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
  def tick
    render_background
    update_player
    update_bullets
    @enemies.move
    @enemies.render
  end
end

def tick args
  $inputs = args.inputs
  $solids = args.outputs.solids
  $sprites = args.outputs.sprites
  $sounds = args.outputs.sounds
  args.state.game ||= InvadersGame.new args
  args.state.game.tick
end
