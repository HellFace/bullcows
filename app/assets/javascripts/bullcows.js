/**
 * Created by martin on 08.04.17.
 */
$(document).on('click', '#sendNameButton', function(event) {
    event.preventDefault();
    App.game.send_name($('#player_name').val());
});
$(document).ready(function(){

});