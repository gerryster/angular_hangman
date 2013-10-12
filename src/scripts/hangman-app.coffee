window.hangman = angular.module('hangman', [])

# From http://stackoverflow.com/questions/1431094/how-do-i-replace-a-character-at-a-particular-index-in-javascript
String.prototype.replaceAt = (index, character)->
  @substr(0, index) + character + @substr(index+character.length)
