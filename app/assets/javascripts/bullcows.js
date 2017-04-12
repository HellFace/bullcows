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
        if (input_action === 'send_name') {
            $('.myName').html(data);
        } else if (!this.isValidNumber(data)) {
            $('#status').html('Please enter a valid number!');
            return false;
        }
        $('#user_input').val('');
        App.game[input_action](data);
    };

    this.waiting_opponent = function()
    {
        this.disableInput('Waiting for opponent to join');
    };

    this.game_pending = function(data)
    {
        opponent = data.opponent_name;
        player_uuid = data.uuid;
        $('.opponent_name').html(opponent);
        $('#user_input').attr('maxlength', 4).attr('placeholder', 'Your number');
        this.enableInput('send_number', 'Your opponent is ' + opponent + '. Please enter your number for the game...');
    };

    this.waiting_number = function()
    {
        this.disableInput('Waiting for your opponent to set his number');
    };

    this.game_start = function(data)
    {
        $('#results_area').show();
        $('#user_input').attr('placeholder', 'Guess');
        this.setTurn(data.turn);
    };

    this.take_turn = function(data)
    {
        this.appendResult(data);
        if (this.checkWin(data)) {
            return true;
        }
        this.setTurn(data.turn);
    };

    this.isValidNumber = function(number)
    {
        var has4digits = /^\d{4}$/.test(number);
        if (!has4digits) {
            return false;
        }

        var digits = number.toString().split('');
        var uniqueDigits = [];
        $.each(digits, function(i, el){
            if($.inArray(el, uniqueDigits) === -1) uniqueDigits.push(el);
        });

        return uniqueDigits.length === 4;
    };

    this.isMyTurn = function(uuid)
    {
        return uuid === player_uuid;
    };

    this.isMyResult = function(uuid)
    {
        return !this.isMyTurn(uuid);
    };

    this.setTurn = function(uuid)
    {
        if (this.isMyTurn(uuid)) {
            this.enableInput('take_guess', 'It\'s your turn. Make a guess!');
        } else {
            this.disableInput('It\'s ' + opponent + '\'s turn. Please wait...');
        }
    };

    this.generateGuessHtml = function(data)
    {
        var html = '<span class="guess-number">' + data.guess + '</span>';

        if (data.cows + data.bulls === 0) {
            return html + '<img src="/images/poo.png" />';
        }
        var i;
        for (i = 0; i < data.cows; i++) {
            html += '<img src="/images/cow.png" />';
        }
        for (i = 0; i < data.bulls; i++) {
            html += '<img src="/images/bull.png" />';
        }

        return html;
    };

    this.appendResult = function(data)
    {
        if (this.isMyResult(data.turn)) {
            divId = '#myGuesses';
            guessClass = 'success';
        } else {
            divId = '#opponentGuesses';
            guessClass = 'warning';
        }

        $('<div>').addClass('guess alert alert-' + guessClass).html( this.generateGuessHtml(data) ).appendTo(divId);
        $(divId).animate({
            scrollTop: $(divId)[0].scrollHeight
        }, 300);
    };

    this.checkWin = function(data)
    {
        if (data.bulls !== 4) {
            return false;
        }

        this.showResultModal(data.turn);

        return true;
    };

    this.showResultModal = function(turn)
    {
        var title, image;
        if (this.isMyResult(turn)) {
            title = 'Congratulations! You win!';
            image = '/images/win.gif';
        } else {
            title = 'Sorry! You are a loser!';
            image = '/images/lose.gif';
        }

        $('#status').html(title);
        $('.modal .modal-title').html(title);
        $('.modal .result-image').attr('src', image);
        $('.modal').modal('show');
    };

};


$(document).on('click', '#sendInputButton', function(event) {
    event.preventDefault();
    App.gamePlay.dispatchChannelAction($('#user_input').val());
});