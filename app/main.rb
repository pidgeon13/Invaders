$gtk.reset

$screen_width = 1280
$screen_height = 720

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
    $solids << [@pos_x, @pos_y, @size, @size, 255, 255, 255]
  end
end

class Player
  attr_reader :pos_x
  attr_reader :pos_y
  def initialize size
    @size = size
    @pos_x =($screen_width - @size) / 2
    @pos_y = 10
    @speed = 12
    @cooldown = 0
    @max_cooldown = 10
  end
  def update
    if($inputs.keyboard.key_held.left && @pos_x >=@speed)
      @pos_x-=@speed
    end
    if($inputs.keyboard.key_held.right && @pos_x <= $screen_width - @size- @speed)
      @pos_x+=@speed
    end
    if(@cooldown > 0)
      @cooldown -= 1
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

class Enemy
  def initialize pos_x, pos_y
    @size = 20
    @pos_x = pos_x
    @pos_y = pos_y
    @speed = 5
  end
  def render
    $solids << [@pos_x, @pos_y, @size, @size, 255, 0, 0]
  end
end

class InvadersGame
  def initialize (args)
    @player = Player.new 30
    @bullets = []
    @enemies = []
    for i in 1..17
      x = ($screen_width/16)*i
      y = $screen_height - 100
      enemy = Enemy.new x , y
      @enemies << enemy
    end
  end
  def render_background
    $solids << [0,0,$screen_width,$screen_height]
  end
  def update_bullets
    if $inputs.keyboard.key_down.space || $inputs.keyboard.key_held.space
      if @player.can_fire
        @bullets << @player.fire_bullet
      end
      puts "#{@bullets.size}"
    end
    @bullets.delete_if {|bullet| bullet.pos_y >= $screen_height}
    @bullets.each do |bullet|
      bullet.move
      bullet.render
    end
  end
  def update_enemies
    @enemies.each do |enemy|
      enemy.render
    end
  end
  def tick
    render_background
    @player.update
    @player.render
    update_bullets
    update_enemies
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
