$(document).ready(function() {

    $('#calendar').fullCalendar({
        height : 800,
        eventSources: [
            {
                 url: '/content/fullcalendar.json',
                 startParam: 'start_time',
                 endParam: 'end_time'
            }
        ]
    })

});