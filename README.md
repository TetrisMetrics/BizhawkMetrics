# Tetris Metrics

Like Tetris Friends, but Tetris Metrics.

## Instructions

1. Install fceux: http://fceux.com/
2. Open Tetris.nes, and get to level select screen.
3. Open Lua console in fceux, and open tetris.lua.
4. Press start button to start game.

## Metrics

### Definitions

* Accommodation - How many of the 7 tetriminos your board can cleanly accommodate - without create a hole or a ledge.
* Max Height - The height of the highest row with a block in it.
* Min Height:
  
  Min height is a little trickier than max height. 
  
  For each column, it gets the height of the highest block in it (in any column).
  Then, the lowest of all _those_ values is returned. The reason for this trickiness is because of holes.
   
* Drought - The number of perices since last I piece

* Pause - The number of pieces it's been since you covered your well.
  * Resets when you clear your well or if you get a dirty tetris.
* Surplus - When you become tetris ready, surplus is the number of blocks North of Perfect. 
            That is, the number of blocks that would remain on the board if you got a tetris immediately.
* Tetris Readiness - The number of tetriminos it takes you to become tetris ready.

  Tetris Readiness is scored in two ways. 
  
  * The number of tetriminos it takes you to get tetris ready at the start of the game.
  * The number of tetriminos since your last tetris, until you become tetris ready again.        
 
* Presses - The number of buttons pressed for a single tetrimino.      
            
### Averages

* Tetris rate

  The percentage of the lines cleared that have been cleared by a tetris.

* Conversion ratio

  Number of tetrises / the number of times you've been ready for a tetris.
  Would be 1 if you never covered your well.

* Average Clear

  The average number of lines you clear every time you clear lines.
  Would be 4 if you only ever got tetrises.

* Average Accommodation
  
   Running total of accommodation scores / number of tetriminos played.
   Aim to get this score as close to 7 as possible.
* Average Max Height

  Running total of max heights / number of tetriminos played.
  A perfect average max height would probably be less than 4, as you build up for a perfect tetris 
  (one that completely clears the board), and then get a tetris immediately. This, however, is certainly
  unattainable. It is currently unknown what a pro players average max height would be close to.
  
* Average Min Height

  Running total of min heights / number of tetriminos played.

  A perfect average min height would probably be less than 0, as you always keep your well open in column 10.
  This also, is certainly unattainable. It is currently unknown what a pro players average min height would be close to.

* Average Drought

  The average number of pieces between I pieces.

* Average Pause

  Running total of all pauses / number of pauses. 
  Helps give an indication of how well you dig, if you are able to uncover your covered wells quickly.
  It's probably ideal to have a very low average pause score, but a higher average pause score
  might not necessarily indicate bad play, but simply brutal RNG.
  
* Average Surplus

  Running total of surplus scores / number of times tetris ready
  If your surplus is very high, it might be an indication that you aren't burning enough.
  However, that might be totally okay if, for example, you are going for maxouts.

* Average Tetris Readiness

  Running total of tetris readiness scores / number of times tetris ready.
  You should probably aim to get your average tetris readiness score as low as possible. 
  You always want to be tetris ready, as fast as possible. Of course, don't sacrifice
  your board state to get there!
  
* Average Presses (Per tetrimino)

  Running total of all button presses / number of tetriminios played.
  For non hyper-tappers, you should probably aim to keep this score low, as a high score 
  would probably indicate a lot of indecision, and probably a lot of last second presses.
  Hyper-tappers probably also want to keep this score low, but their average score would 
  likely be much higher than that of a non-hyper-tapper. 
  It is currently unknown what a pro players average presses per tetrimino would be close to
  for hyper-tappers and non-hyper-tappers.

## Notes

I included json.lua from here: http://files.luaforge.net/releases/json/json/0.9.50
