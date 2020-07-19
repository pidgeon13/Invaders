$screen_width = 1280
$screen_height = 720
$game_width = 600

$game_left_extent = ($screen_width-$game_width)/2
$game_right_extent=$game_left_extent + $game_width

def RGB symbol
  return [255,55,55] if symbol == :red
  return [100,255,100] if symbol == :green
  return [128,155,255] if symbol == :blue
  return [255,255,255] if symbol == :white
  return [0,0,0] if symbol == :black
  return [64,64,64] if symbol == :dark_grey
  return [128,128,128] if symbol == :light_grey
  return [255, 0, 255] if symbol == :purple
end

class Bullet
  attr_reader :pos_x
  attr_reader :pos_y
  attr_reader :needs_deleting
  def initialize pos_x, pos_y, speed, dir = 1, colour = :purple
    @pos_x = pos_x
    @pos_y = pos_y
    @dir = dir
    @speed = speed
    @size = 5
    @needs_deleting = false
    @colour = colour
  end
  def move
    @pos_y += (@dir*10*@speed)
  end
  def render
    $solids << [@pos_x, @pos_y, @size, @size, *RGB(@colour)]
  end
  def remove
    @needs_deleting = true
  end
end

class Player
  attr_reader :pos_x
  attr_reader :pos_y
  attr_reader :colour
  def initialize size = 60
    @size_x = size
    @size_y = @size_x*0.75
    @pos_x = ($screen_width - @size_x) / 2
    @pos_y = 10
    @speed = 8
    @cooldown = 0
    @max_cooldown = 30
    @bullet_speed = 1
    @colour = 0
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
    if(@pos_x <= $game_right_extent - @size_x - @speed)
      @pos_x+=@speed
    end
  end
  def fire_bullet
    @cooldown=@max_cooldown
    $sounds << "audio/flaunch.wav"
    return Bullet.new @pos_x + (@size_x/2), @pos_y + @size_x, @bullet_speed
  end
  def hit_by bullet
    [bullet.pos_x,bullet.pos_y].intersect_rect? [@pos_x, @pos_y, @size_x, @size_y]
  end
  def can_fire
    return @cooldown <= 0
  end
  def set_colour colour
    @colour = colour
  end
  def sprite number
    case number
    when 0 then "sprites/player_green.png"
    when 1 then "sprites/player_blue.png"
    when 2 then "sprites/player_red.png"
    when 3 then "sprites/player_orange.png"
    end
  end
  def render
    $sprites << [@pos_x, @pos_y, @size_x, @size_y, sprite(@colour)]
  end
  def increase_speed ratio = 1.3
    @speed*=ratio
  end
  def increase_bullet_speed ratio = 1.5
    @bullet_speed*=ratio
  end
  def decrease_cooldown ratio = 0.95
    @max_cooldown*=ratio
  end
  def reset_attributes
    @speed = 8
    @bullet_speed = 1
    @max_cooldown = 30
  end
end

class Enemy_Grid
  attr_reader :pos_y
  attr_reader :number_x
  attr_reader :number_y
  def initialize number_x, number_y, velocity = 1, left = $game_left_extent, top = $screen_height, size_x = 40
    @number_x = number_x
    @number_y = number_y
    @size_x = size_x
    @size_y = size_x*0.8
    @pos_x = left
    @pos_y = top - @number_y * @size_y
    @grid = Array.new(@number_x) {Array.new(@number_y, 1)}
    @velocity = velocity
    @vertical_jump = @size_y/2
    @max_bullet_cooldown = 60
    @current_bullet_cooldown = @max_bullet_cooldown
  end
  def render
    for i in 0..@grid.length-1
      column=@grid[i]
      for j in 0..column.length-1
        if(column[j]!=0)
          $sprites << [@pos_x+i*@size_x, @pos_y + j*@size_y, @size_x, @size_y, "sprites/enemyBlue2.png"]
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
  def true_center_pos column_index, row_index
    return [@pos_x + ((2*column_index+1)*@size_x)/2, @pos_y + ((2*row_index+1)*@size_y)/2]
  end
  def fire_bullet column_index
    row_index = @grid[column_index].index {|x| x != 0} 
    if !row_index.nil?
      @current_bullet_cooldown = @max_bullet_cooldown
      return Bullet.new(*true_center_pos(column_index, row_index), 0.5 , -1, :red)
    else
      return nil
    end
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
    if(@grid.empty?)
      return false
    end
    leading_zeros = @grid.map { |col| number_leading_zeros col}
    rows_to_clean = leading_zeros.min
    @grid.each do |column|
      column.slice! 0, rows_to_clean
    end
    @number_y -= rows_to_clean
    @pos_y += rows_to_clean*@size_y
    return true
  end
  def update
    @current_bullet_cooldown -= 1
  end
  def can_fire
    return @current_bullet_cooldown <= 0
  end
  def clean
    clean_columns
    clean_rows
  end
  def any_alive
    return @grid.length > 0
  end
end

class InvadersGame
  def initialize (args)
    @player = Player.new
    @bullets = []
    @enemies = Enemy_Grid.new 2, 2, 1
    @enemy_bullets = []
    @death_point = 100
    @previous_state = :main_menu
    @current_state = :main_menu
    @score = 0
    @number_red=0
    @number_green=0
    @number_blue=0
    @high_score = 0
    @current_level = 1
    @current_choice = 0
    $sounds << "audio/DSCut.ogg"
    @current_controls_type = :keyboard
  end
  def render_uprade_array colour, pos_x, pos_y, number
    size_x = 28
    size_y = 38
    tens = (number / 10).floor
    rem = number.to_i % 10
    for i in 0..rem-1
      $sprites << [pos_x - 0.5*size_x, pos_y + i*(size_y+2), size_x, size_y, upgrade_sprite(colour)] 
    end
    if(tens > 0)
      $labels << [pos_x, pos_y-size_y/2, "#{tens*10 }", 4, 1, *RGB(colour)]
    end
  end
  def render_upgrades
    upgrade_start_y = $screen_height/8
    render_uprade_array :red, $game_left_extent/4, upgrade_start_y, @number_red
    render_uprade_array :green, 2*$game_left_extent/4, upgrade_start_y, @number_green
    render_uprade_array :blue, 3*$game_left_extent/4, upgrade_start_y, @number_blue
  end
  def render_controls
    controls_x = $game_right_extent+$game_width/3
    arrows_y = $screen_height/3
    space_y = arrows_y - 70
    enter_y = space_y - 70
    $labels << [controls_x - 15, arrows_y + 60, "Move:", 7, 2, 255,255,255]
    $labels << [controls_x - 15, space_y + 50, "Shoot:", 7, 2, 255,255,255]
    $labels << [controls_x - 15, enter_y  + 45, "Pause:", 7, 2, 255,255,255]
    case @current_controls_type
    when :keyboard
      $sprites << [controls_x,arrows_y, 120, 84, "sprites/left_right.png"]
      $sprites << [controls_x +20,space_y, 80, 54, "sprites/space.png"]
      $sprites << [controls_x+ 35,enter_y, 50, 50, "sprites/esc.png"]
    when :controller
      $sprites << [controls_x,arrows_y +15, 50, 50, "sprites/controller_left.png"]
      $sprites << [controls_x + 70,arrows_y+15, 50, 50, "sprites/controller_right.png"]
      $sprites << [controls_x + 30,space_y, 60, 60, "sprites/controller_a.png"]
      $sprites << [controls_x + 35,enter_y, 50, 50, "sprites/controller_start.png"]
    end
  end
  def render_background
    $solids << [0,0, $screen_width, $screen_height, 30, 30, 30]
    $solids << [$game_left_extent, 0, $game_width, $screen_height]
    $lines << [$game_left_extent, @death_point, $game_right_extent, @death_point, 255,255,255]
    $labels << [$game_right_extent+$game_width/4,7*$screen_height/8, "Score: #{@score}", 4, 1, 255, 255, 255]
    $labels << [$game_right_extent+$game_width/4,3*$screen_height/4, "High Score: #{@high_score }", 4, 1, 255, 255, 255]
    $labels << [$game_left_extent-$game_width/4,7*$screen_height/8, "Level: #{@current_level }", 4, 1, 255, 255, 255]
    render_controls
    render_upgrades
  end
  def update_player_bullets
    if $inputs.keyboard.key_down.space || $inputs.keyboard.key_held.space || $inputs.controller_one.key_down.a || $inputs.controller_one.key_held.a
      if @player.can_fire
        @bullets << @player.fire_bullet
      end
    end
    @bullets.delete_if {|bullet| bullet.pos_y >= $screen_height || bullet.needs_deleting}
    @bullets.each do |bullet|
      bullet.move
      if(@enemies.hitting bullet)
        bullet.remove
        @score+=1
        @high_score = [@high_score, @score].max
      end
      bullet.render
    end
  end
  def render_player
    @player.render
  end
  def update_player
    if ($inputs.keyboard.key_held.left || $inputs.controller_one.key_held.left)
      @player.move_left
    end
    if ($inputs.keyboard.key_held.right || $inputs.controller_one.key_held.right)
      @player.move_right
    end
    if(toggling_pause)
      set_state :pause
    end
    @player.update
    render_player
  end
  def render_enemies
    @enemies.render
  end
  def fire_enemy_bullets
    enemy_bullet = @enemies.fire_bullet(rand(@enemies.number_x))
    if !enemy_bullet.nil?
      @enemy_bullets << enemy_bullet
    end
  end
  def update_enemy_bullets
    @enemy_bullets.each do |bullet|
      bullet.move
      bullet.render
      if(@player.hit_by bullet)
        set_state(:game_over)
      end
    end
    @enemy_bullets.delete_if {|bullet| bullet.pos_y <= 0}
  end
  def update_enemies
    @enemies.move
    @enemies.update
    if(@enemies.can_fire)
      fire_enemy_bullets
    end
    update_enemy_bullets
    render_enemies
    if(@enemies.pos_y <= @death_point)
      set_state(:game_over)
    end
  end
  def render_game_over
    $labels << [$game_left_extent+$game_width/2,3*$screen_height/4, "Game Over", 10, 1, 255, 255, 255]
    $labels << [$game_left_extent+$game_width/2,5*$screen_height/8, "Press the enter key to play again", 4, 1, 255, 255, 255] 
  end
  def start_level
    case @current_level
    when 1
      restart 2, 2, 1, true
    when 2
      restart 10, 4, 1.5
    when 3
      restart 12, 4, 2
    else
      restart 12, 5, 0.4*(@current_level+1)
    end 
  end
  def set_state symbol
    @previous_state = @current_state
    @current_state = symbol
  end
  def restart enemy_grid_x, enemy_grid_y, velocity, reset_to_start = false
    @bullets = []
    @enemy_bullets = []
    @enemies = Enemy_Grid.new enemy_grid_x, enemy_grid_y, velocity
    set_state(:playing)
    if reset_to_start
      @score=0
      @number_red=0
      @number_green=0
      @number_blue=0
      @player.reset_attributes
    end
  end
  def restart_game_if_prompted
    if $inputs.keyboard.key_down.enter || $inputs.controller_one.key_down.start
      @current_level = 1
      start_level
    end
  end
  def move_selection
    if ($inputs.keyboard.key_down.left || $inputs.controller_one.key_down.left)
      @current_choice -= 1
    end
    if ($inputs.keyboard.key_down.right || $inputs.controller_one.key_down.right)
      @current_choice += 1
    end
  end
  def update_choices
    if(selection_made)
      start_level
      case @current_choice % 3
      when 0
        @player.increase_bullet_speed
        @number_red+=1
      when 1
        @player.increase_speed
        @number_green+=1
      when 2
        @player.decrease_cooldown
        @number_blue+=1
      end
    end  
    move_selection
  end
  def upgrade_sprite symbol
    case symbol
    when :red
      return "sprites/red.png"
    when :green
      return "sprites/green.png"
    when :blue
      return "sprites/blue.png"
    end
  end
  def render_choices
    choices_size_x = 70
    choices_size_y = 95
    expanded_size_x = choices_size_x * 1.5
    expanded_size_y = choices_size_y * 1.5
    left_x = $game_left_extent + $game_width/4
    center_x = $game_left_extent + 2*$game_width/4
    right_x = $game_left_extent + 3*$game_width/4
    choice_y = 2*$screen_height/3
    choice_standard_y= choice_y - 0.5*choices_size_y
    choice_expanded_y = choice_y - 0.5*expanded_size_y
    case @current_choice % 3
    when 0
      $sprites << [left_x - 0.5*expanded_size_x, choice_expanded_y, expanded_size_x, expanded_size_y, upgrade_sprite(:red)]
      $sprites << [center_x - 0.5*choices_size_x, choice_standard_y, choices_size_x, choices_size_y, upgrade_sprite(:green)]
      $sprites << [right_x - 0.5*choices_size_x, choice_standard_y, choices_size_x, choices_size_y, upgrade_sprite(:blue)]
      text = "Increase bullet speed"
      colour=:red
    when 1
      $sprites << [left_x - 0.5*choices_size_x, choice_standard_y, choices_size_x, choices_size_y, upgrade_sprite(:red)]
      $sprites << [center_x - 0.5*expanded_size_x, choice_expanded_y, expanded_size_x, expanded_size_y, upgrade_sprite(:green)]
      $sprites << [right_x - 0.5*choices_size_x, choice_standard_y, choices_size_x, choices_size_y, upgrade_sprite(:blue)]
      text="Increase movement speed"
      colour=:green
    when 2
      $sprites << [left_x - 0.5*choices_size_x, choice_standard_y, choices_size_x, choices_size_y, upgrade_sprite(:red)]
      $sprites << [center_x - 0.5*choices_size_x, choice_standard_y, choices_size_x, choices_size_y, upgrade_sprite(:green)]
      $sprites << [right_x - 0.5*expanded_size_x, choice_expanded_y, expanded_size_x, expanded_size_y, upgrade_sprite(:blue)]
      text = "Increase rate of fire"
      colour=:blue
    end
    $labels << [center_x,$screen_height/2, text, 4, 1, *RGB(colour)]
    $labels << [center_x,3*$screen_height/8, "Press Enter to select", 2, 1, 255, 255, 255]
  end
  def get_text_height string
    return $gtk.calcstringbox(string, 20)[1]
  end
  def render_full_background
    $solids << [0,0, $screen_width, $screen_height]
  end
  def render_menu
    render_full_background
    start_y = 2*$screen_height/3
    options_y = $screen_height/2
    quit_y = $screen_height/3
    case @current_choice % 3
    when 0 
      start_font_size = 20
      options_font_size = 10
      quit_font_size = 10
      start_colour = :red
      options_colour = :white
      quit_colour = :white
    when 1
      start_font_size = 10
      options_font_size = 20
      quit_font_size = 10
      start_colour = :white
      options_colour = :red
      quit_colour = :white
    when 2
      start_font_size = 10
      options_font_size = 10
      quit_font_size = 20
      start_colour = :white
      options_colour = :white
      quit_colour = :red
    end
    $labels << [$game_left_extent+$game_width/2, start_y, "Start", start_font_size, 1, *RGB(start_colour)]
    $labels << [$game_left_extent+$game_width/2, options_y, "Options", options_font_size, 1, *RGB(options_colour)]
    $labels << [$game_left_extent+$game_width/2, quit_y, "Quit", quit_font_size, 1, *RGB(quit_colour)]
  end
  def moving_selection_up
    $inputs.keyboard.key_down.up || $inputs.controller_one.key_down.up
  end
  def moving_selection_down
    $inputs.keyboard.key_down.down || $inputs.controller_one.key_down.down
  end
  def update_menu
    if(selection_made)
      case @current_choice % 3
      when 0
        @current_level = 1
        start_level
      when 1
        set_state(:options)
        @current_choice = @player.colour
      when 2
        exit
      end
    end 
    if (moving_selection_up)
      @current_choice -= 1
    end
    if (moving_selection_down)
      @current_choice += 1
    end
  end
  def toggling_pause
    $inputs.keyboard.key_down.escape || $inputs.controller_one.key_down.start
  end
  def render_pause
    $labels << [$game_left_extent+$game_width/2,2*$screen_height/3, "Paused", 15, 1, *RGB(:white)]
    render_player
    if(toggling_pause)
      set_state :playing
    end
  end
  def selection_made 
    $inputs.keyboard.key_down.space || $inputs.controller_one.key_down.a
  end
  def render_ship_options
    left_x = $screen_width/5
    center_left_x = 2*$screen_width/5
    center_right_x = 3*$screen_width/5
    right_x = 4*$screen_width/5
    size_x = 100
    size_y = size_x*0.75
    expanded_size_x = size_x * 1.5
    expanded_size_y = size_y * 1.5
    choice_y = 2*$screen_height/3
    choice_standard_y= choice_y - 0.5*size_y
    choice_expanded_y = choice_y - 0.5*size_y
    case @current_choice % 4
    when 0
      $sprites << [left_x - 0.5*expanded_size_x, choice_expanded_y, expanded_size_x, expanded_size_y, @player.sprite(0)]
      $sprites << [center_left_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(1)]
      $sprites << [center_right_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(2)]
      $sprites << [right_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(3)]
    when 1
      $sprites << [left_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(0)]
      $sprites << [center_left_x - 0.5*expanded_size_x, choice_expanded_y, expanded_size_x, expanded_size_y, @player.sprite(1)]
      $sprites << [center_right_x- 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(2)]
      $sprites << [right_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(3)]
    when 2
      $sprites << [left_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(0)]
      $sprites << [center_left_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(1)]
      $sprites << [center_right_x - 0.5*expanded_size_x, choice_expanded_y, expanded_size_x, expanded_size_y, @player.sprite(2)]
      $sprites << [right_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(3)]
    when 3
      $sprites << [left_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(0)]
      $sprites << [center_left_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(1)]
      $sprites << [center_right_x - 0.5*size_x, choice_standard_y, size_x, size_y, @player.sprite(2)]
      $sprites << [right_x - 0.5*expanded_size_x, choice_expanded_y, expanded_size_x, expanded_size_y, @player.sprite(3)]
    end
  end
  def update_ship_options
    if(selection_made)
      @player.set_colour @current_choice
      @current_choice = 1
      set_state(@previous_state)
    end
    move_selection
  end
  def update_controls_type
    if ($inputs.controller_one.key_down.truthy_keys.length > 0)
      @current_controls_type = :controller
    elsif($inputs.keyboard.key_down.truthy_keys.length > 0)
      @current_controls_type = :keyboard
    end
  end
  def tick
    update_controls_type
    case @current_state
    when :main_menu
      render_menu
      update_menu
    when :options
      render_full_background
      render_ship_options
      update_ship_options
    when :pause
      render_background
      render_pause
    when :game_over
      render_background
      render_game_over
      restart_game_if_prompted
    when :picking_upgrade
      render_background
      update_choices
      render_choices
    when :playing
      render_background
      update_player
      update_player_bullets
      @enemies.clean
      if(@enemies.any_alive)
        update_enemies
      else
        set_state(:picking_upgrade)
        @current_choice=1
        @current_level+=1
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
