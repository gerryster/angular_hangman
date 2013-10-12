hangman.factory 'gameState', ()->
  WORDS: [
    'cat', 'dog', 'pork', 'milk', 'love', 'Eli', 'daddy', 'mommy', 'pig',
    'cow', 'chair', 'ball', 'kite', 'bat', 'bird', 'one', 'two', 'three',
    'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'
  ],
  MAX_INCORRECT_GUESSES: 10,

  _randomWord: ()->
    @WORDS[Math.floor(Math.random() * @WORDS.length)]

  newGame: ()->
    @incorrectCount = 0
    @gameOver = false
    @won = false
    @answer = @._randomWord()
    # create a placeholder space character for every letter in the answer
    @guess = new Array(@answer.length + 1).join(" ")

    console.log "Game answer: #{@answer}"

  guessLetter: (letter)->
    letter = letter.toLocaleLowerCase()
    if @answer.toLocaleLowerCase().indexOf(letter) >= 0
      @._updateGuess(letter)
    else
      @incorrectCount++

    @.checkGameOver()

  # update the guess with the found letter
  _updateGuess: (guessLetter)->
    cursor = 0
    _.map(@answer.split(""),
      (answerLetter)->
        if guessLetter == answerLetter.toLocaleLowerCase()
          @guess = @guess.replaceAt(cursor, answerLetter)
        cursor++
      , @)

  checkGameOver: ()->
    if @answer == @guess
      @won = true
      @gameOver = true
    else if @incorrectCount == @MAX_INCORRECT_GUESSES
      @gameOver = true

  resetGame: ()->
    @.newGame()
