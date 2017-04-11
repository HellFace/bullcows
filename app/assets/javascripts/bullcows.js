/**
 * Created by martin on 08.04.17.
 */
function getUserInput()
{
	return $('#user_input').val();
}

var Game = function() {
	var input_action;
	var player_uuid;
	var opponent;

	this.init = function()
	{
		this.enableInput('send_name', 'You are connected. Please set your name and we will find you an opponent!');
	};

	this.disableInput = function(status)
	{
        $('#status').html(status);
		$('#user_input').attr('disabled', true);
		$('#sendInputButton').attr('disabled', true);
	};

	this.enableInput = function(action, status)
	{
        $('#status').html(status);
		$('#user_input').attr('disabled', false);
		$('#sendInputButton').attr('disabled', false);
		input_action = action;
	};

	this.dispatchAction = function(data)
	{
		this[data.action](data);
	};

	this.dispatchChannelAction = function(data)
	{
		$('#user_input').val('');
		App.game[input_action](data);
	};

	this.set_player = function (data) {
        player_uuid = data.uuid;
    };

	this.waiting_opponent = function()
	{
		this.disableInput('Waiting for opponent to join');
	};

	this.game_pending = function(data)
	{
		opponent = data.opponent_name;
		this.enableInput('send_number', 'Your opponent is ' + opponent + '. Please enter your number for the game...');
	};

	this.waiting_number = function()
	{
		this.disableInput('Waiting for your opponent to set his number');
	};

	this.game_start = function(data)
	{
        this.setTurn(data.turn);
	};

	this.take_turn = function(data)
	{
		$('#status').html('Result is ' + data.bulls + ' bulls and ' + data.cows + 'cows!')
	};

	this.isMyTurn = function(uuid)
    {
	    return uuid === player_uuid;
    };

	this.setTurn = function(uuid)
    {
        if (this.isMyTurn(uuid)) {
            this.enableInput('take_guess', 'It\'s your turn. Make a guess!');
        } else {
            this.disableInput('It\'s ' + opponent + '\'s turn. Please wait...');
        }
    }

};


$(document).on('click', '#sendInputButton', function(event) {
  event.preventDefault();
  App.gamePlay.dispatchChannelAction($('#user_input').val());
});