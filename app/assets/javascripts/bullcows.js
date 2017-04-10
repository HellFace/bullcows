/**
 * Created by martin on 08.04.17.
 */
function getUserInput()
{
	return $('#user_input').val();
}

var Game = function() {
	var input_action;
	var opponent;

	this.init = function()
	{
		$('#status').html('You are connected. Please set your name and we will find you an opponent!');
		this.enableInput('send_name');
	}

	this.disableInput = function()
	{
		$('#user_input').attr('disabled', true);
		$('#sendInputButton').attr('disabled', true);
	}

	this.enableInput = function(action)
	{
		$('#user_input').attr('disabled', false);
		$('#sendInputButton').attr('disabled', false);
		input_action = action;
	}

	this.dispatchAction = function(data)
	{
		this[data.action](data);
	}

	this.dispatchChannelAction = function(data)
	{
		$('#user_input').val('');
		App.game[input_action](data);
	}

	this.waiting_opponent = function()
	{
		$('#status').html('Waiting for opponent to join');
		this.disableInput();
	}

	this.game_pending = function(data)
	{
		opponent = data.opponent_name;
		$('#status').html('Your opponent is ' + opponent + '. Please enter your number for the game...');
		this.enableInput('send_number');
	}

	this.waiting_number = function()
	{
		$('#status').html('Waiting for your opponent to set his number');
		this.disableInput();
	}

	this.game_start = function()
	{
		$('#status').html('Game starts... it\'s someone\'s turn');
		this.enableInput('take_guess');
	}

	this.take_turn = function(data)
	{
		$('#status').html('Result is ' + data.bulls + ' bulls and ' + data.cows + 'cows!')
	}

};


$(document).on('click', '#sendInputButton', function(event) {
  event.preventDefault();
  App.gamePlay.dispatchChannelAction($('#user_input').val());
});