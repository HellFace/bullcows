/**
 * Created by martin on 08.04.17.
 */
$(document).on('click', '#sendNameButton', function(event) {
    event.preventDefault();
    App.game.send_name($('#player_name').val());
});
$(document).on('click', '#sendNumberButton', function(event) {
    event.preventDefault();
    App.game.send_number($('#player_number').val());
});
$(document).ready(function(){

});