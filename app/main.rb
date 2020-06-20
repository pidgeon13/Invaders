$gtk.reset

$screen_width = 1280
$screen_height = 720
$game_width = 600

$game_left_extent = ($screen_width-$game_width)/2
$game_right_extent=$game_left_extent + $game_width

class Bullet
  attr_reader :pos_x
  attr_reader :pos_y
  def initialize pos_x, pos_y, dir
    @pos_x = pos_x
    @pos_y = pos_y
    @dir = dir
    @size = 5
  end
  def move
    @pos_y += (@dir*10)
  end
  def render
    $solids << [@pos_x, @pos_y, @size, @size, 255, 0, 255]
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
    $sprites << [@pos_x, @pos_y, @size*1.2, @size*1.9, "sprites/kestral.png"]
  end
end

class Enemy_Grid
  def initialize number_x, number_y, pos_x = $game_left_extent , pos_y = $screen_height, offset = 50
    @number_x = number_x
    @number_y = number_y
    @pos_x = pos_x
    @pos_y = pos_y
    @offset = offset
    @grid = Array.new(@number_x) {Array.new(@number_y, 1)}
    @velocity = 1
    @vertical_jump = @offset/2
  end
  def render
    for i in 0..@grid.length-1
      column=@grid[i]
      for j in 1..column.length
        if(column[j]!=0)
          $sprites << [@pos_x+i*@offset, @pos_y - (j+1)*@offset, @offset, @offset, "sprites/Mantis.png"]
        end
      end
    end
  end
  def length
    return @offset*@number_x
  end
  def height
    return @offset*@number_y
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
end

class InvadersGame
  def initialize (args)
    @player = Player.new 30
    @bullets = []
    @enemies = Enemy_Grid.new 10, 3
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
    @bullets.delete_if {|bullet| bullet.pos_y >= $screen_height}
    @bullets.each do |bullet|
      bullet.move
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
