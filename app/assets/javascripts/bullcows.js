/**
 * Created by martin on 08.04.17.
 */
$(document).on('click', '#sendInputButton', function(event) {
    event.preventDefault();
    App.gamePlay.dispatchChannelAction($('#user_input').val());
});

var Game = function() {
    var input_action;
    var player_uuid;
    var opponent;

    /**
     * Connection has been established. Player must set his name.
     */
    this.init = function()
    {
        this.enableInput('send_name', 'You are connected. Please set your name and we will find you an opponent!');
    };

    /**
     * Disable the user input. Waiting for opponent to join or their input.
     *
     * @param status - set the status text
     */
    this.disableInput = function(status)
    {
        $('#status').html(status);
        $('#user_input').attr('disabled', true);
        $('#sendInputButton').attr('disabled', true);
    };

    /**
     * Enable the user input and set the channel action it will perform next
     *
     * @param action - the next channel action, sent over the cable, when sending the user input
     * @param status - the status text
     */
    this.enableInput = function(action, status)
    {
        $('#status').html(status);
        $('#user_input').attr('disabled', false);
        $('#sendInputButton').attr('disabled', false);
        input_action = action;
    };

    /**
     * Execute one of the local functions, based on the channel received data, broadcast by server
     *
     * @param data
     */
    this.dispatchAction = function(data)
    {
        this[data.action](data);
    };

    /**
     * Send data to the cable
     *
     * @param data
     * @returns {boolean}
     */
    this.dispatchChannelAction = function(data)
    {
        // The name is the only input, which must not validate as number
        if (input_action === 'send_name') {
            $('.myName').html(data);
        } else if (!this.isValidNumber(data)) {
            $('#status').html('Please enter a valid number!');
            return false;
        }

        $('#user_input').val('');
        App.game[input_action](data);
    };

    /**
     * Waiting_opponent action, received from cable
     * User has set his name and is waiting for an opponent to join
     */
    this.waiting_opponent = function()
    {
        this.disableInput('Waiting for opponent to join');
    };

    /**
     * Game_pending action, received from cable
     * Opponent is found, user must set his number
     *
     * @param data
     */
    this.game_pending = function(data)
    {
        opponent = data.opponent_name;
        player_uuid = data.uuid;
        $('.opponent_name').html(opponent);
        $('#user_input').attr('maxlength', 4).attr('placeholder', 'Your number');
        this.enableInput('send_number', 'Your opponent is ' + opponent + '. Please enter your number for the game...');
    };

    /**
     * Waiting_number action, received from cable
     * User has set his number, but their opponent has not
     */
    this.waiting_number = function()
    {
        this.disableInput('Waiting for your opponent to set his number');
    };

    /**
     * Game_start action, received from cable
     * All is set, show the game board and activate the input if it's user's turn
     *
     * @param data
     */
    this.game_start = function(data)
    {
        $('#results_area').show();
        $('#user_input').attr('placeholder', 'Guess');
        this.setTurn(data.turn);
    };

    /**
     * Take_turn action, received from cable
     * A guess has been made, add it to the board, check for win, and set the next turn
     *
     * @param data
     * @returns {boolean}
     */
    this.take_turn = function(data)
    {
        this.appendResult(data);
        if (this.checkWin(data)) {
            return true;
        }
        this.setTurn(data.turn);
    };

    /**
     * Validate a number input - 4 different digits
     * @param number
     * @returns {boolean}
     */
    this.isValidNumber = function(number)
    {
        // 4 digit number
        var has4digits = /^\d{4}$/.test(number);
        if (!has4digits) {
            return false;
        }

        // Unique digits
        var digits = number.toString().split('');
        var uniqueDigits = [];
        $.each(digits, function(i, el){
            if($.inArray(el, uniqueDigits) === -1) uniqueDigits.push(el);
        });

        return uniqueDigits.length === 4;
    };

    /**
     * Check if it is current user's turn
     *
     * @param uuid
     * @returns {boolean}
     */
    this.isMyTurn = function(uuid)
    {
        return uuid === player_uuid;
    };

    /**
     * Check if the received result from the take_turn action was the current user's guess
     * If the current turn is not the current user, then the last turn was his
     *
     * @param uuid
     * @returns {boolean}
     */
    this.isMyResult = function(uuid)
    {
        return !this.isMyTurn(uuid);
    };

    /**
     * Check whose turn it is, and activate their input, disable the opponent's one
     *
     * @param uuid
     */
    this.setTurn = function(uuid)
    {
        if (this.isMyTurn(uuid)) {
            this.enableInput('take_guess', 'It\'s your turn. Make a guess!');
        } else {
            this.disableInput('It\'s ' + opponent + '\'s turn. Please wait...');
        }
    };

    /**
     * Generate the HTML for a single guess and result on the game board
     *
     * @param data
     * @returns {string}
     */
    this.generateGuessHtml = function(data)
    {
        var html = '<span class="guess-number">' + data.guess + '</span>';

        // Nothing - 0 bulls and 0 cows
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

    /**
     * Add the guess to the board to the appropriate column
     *
     * @param data
     */
    this.appendResult = function(data)
    {
        // This was current user's guess
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

    /**
     * Check if the game has ended - last guess has 4 bulls
     *
     * @param data
     * @returns {boolean}
     */
    this.checkWin = function(data)
    {
        if (data.bulls !== 4) {
            return false;
        }

        this.showResultModal(data.turn);

        return true;
    };

    /**
     * Show the Winner / Loser Modal when the game ends
     *
     * @param turn
     */
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

        this.disableInput(title);
        $('.modal .modal-title').html(title);
        $('.modal .result-image').attr('src', image);
        $('.modal').modal('show');
    };

};