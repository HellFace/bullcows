//= require_tree ./cable
//= require_self

var PlayerUpdater = function() {
    var player_uuid;

    this.init = function(uuid)
    {
        player_uuid = uuid;
    };

    this.refreshList = function(data)
    {
        $('#players_area').html('');
        $.each(data, function(index, player) {
            if (player.status && player.uuid != player_uuid) {
            $('<a>').attr('href', '#').attr('data-uuid', player.uuid).addClass('alert alert-' + (player.status == 'waiting' ? 'success' : 'danger')).html(player.name).appendTo($('#players_area'))
            }
        });
    }
};




var Game = function() {
    var input_action;
    var player_uuid;
    var opponent;
    var invited_uuid;

    /**
     * Connection has been established. Tell the server you are ready to play
     */
    this.init = function(uuid)
    {
        player_uuid = uuid;
        this.setWaiting();
    };

    this.setWaiting = function()
    {
        input_action = 'set_waiting';
        this.dispatchChannelAction();
    };

    /**
     * The connection with the server failed
     */
    this.connectionFailed = function()
    {
    	this.showModal('disconnected', 'You have been disconnected. Please refresh to try again!', 'disconnected');
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
        $('#user_input').attr('disabled', false).focus();
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
     * Validate data sent to the cable
     *
     * @param data
     */
    this.validateChannelActionData = function(data)
    {
        var number_actions = ['send_number', 'take_guess'];
        if ($.inArray(input_action, number_actions) >= 0 && !this.isValidNumber(data)) {
            $('#status').html('Please enter a valid number!');
            return false;
        }

        return true;
    };

    /**
     * Send data to the cable
     *
     * @param data
     * @param action?
     * @returns {boolean}
     */
    this.dispatchChannelAction = function(data)
    {
        if (!this.validateChannelActionData(data)) {
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
        this.cleanupGame();
        opponent = data.opponent_name;
        $('.opponent_name').html(opponent);
        $('#user_input').attr('placeholder', 'Your number');
        $('#players_area').hide();
        this.hideAllModals();
        this.enableInput('send_number', 'Your opponent is ' + opponent + '. Please enter your number for the game...');
    };

    this.game_withdraw = function()
    {
    	this.showModal('disconnected', 'Your opponent has quit!', 'withdraw');
    };

    this.go_dashboard = function(data)
    {
        $('#players_area').show();
        $('#results_area').hide();
        invited_uuid = null;
        this.hideAllModals();
        this.disableInput(data.message)
    };

    this.receive_invite = function(data)
    {
        invited_uuid = data.uuid;
        $('.invitationName').html(data.name);
        this.showModal('receivedInvitation', 'Received an invitation from ' + data.name);
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
     * Something went terribly wrong
     * Redirect the user to the home page
     */
    this.game_quit = function()
    {
        window.location = '/';
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

        var title, image;
        if (this.isMyResult(data.turn)) {
            title = 'Congratulations! You win!';
            image = 'win';
        } else {
            title = 'Sorry! You are a loser!';
            image = 'lose';
        }

        this.showModal('gameResult', title, image);

        return true;
    };


    this.showModal = function(modalType, title, image)
    {
        this.disableInput(title);
        var modalId = '#' + modalType + 'Modal';

        $(modalId + ' .modal-title').html(title);

        if ($(modalId + ' .result-image').length) {
            $(modalId + ' .result-image').hide();
            $(modalId + ' #' + image + 'Image').show();
        }

        $(modalId).modal('show');

    };

    this.hideAllModals = function()
    {
        $('.modal').modal('hide');
    };

    this.sendInvite = function(uuid)
    {
        input_action = 'send_invite';
        invited_uuid = uuid;
        this.showModal('sentInvitation', 'Sent an invitation. Waiting for response...');
        this.dispatchChannelAction(uuid);
    };

    this.answerInvite = function(answer)
    {
        input_action = 'answer_invite';
        this.dispatchChannelAction({uuid: invited_uuid, accept: answer});
    };

    this.cancelInvite = function()
    {
        input_action = 'cancel_invite';
        this.dispatchChannelAction(invited_uuid);
    };

    this.startRematch = function()
    {
    	input_action = 'rematch';
    	this.dispatchChannelAction(invited_uuid);
    };

    this.cleanupGame = function()
    {
    	$('.playerGuesses').html('');
    	$('.opponent_name').html('Unknown');
    	$('#myNumber').html('not set');
        this.hideAllModals();
    	$('#results_area').hide();
        $('#players_area').hide();
    };

};

$(document).on('click', '#sendInputButton', function(event) {
    event.preventDefault();
    App.gamePlay.dispatchChannelAction($('#user_input').val());
});

$(document).on('click', '.btn-rematch', function(event) {
    App.gamePlay.startRematch();
});

$(document).on('click', '.btn-dashboard, .btn-disconnect', function(event) {
    App.gamePlay.setWaiting();
});

$(document).on('click', '#players_area a.alert-success', function(event) {
    event.preventDefault();
    App.gamePlay.sendInvite($(this).data('uuid'));
});

$(document).on('click', '#players_area a.alert-danger', function(event) {
    event.preventDefault();
});

$(document).on('click', '.btn-answer-invitation', function(event) {
    App.gamePlay.answerInvite($(this).data('answer'));
});

$(document).on('click', '.btn-cancel-invitation', function(event) {
    App.gamePlay.cancelInvite();
});

$(document).ready(function() {
    $('.modal').modal({backdrop: 'static', keyboard: false, show: false});
});