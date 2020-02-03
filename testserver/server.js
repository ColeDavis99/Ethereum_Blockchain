var express = require('express');
var app = express();
var path = require('path');
var fs = require('fs');

app.set('view engine', 'ejs');



/*===========================
	ROUTE THE PAGES
=============================*/

// viewed at http://localhost:3000
app.get('/', function (req, res) {
  readAuditLog();
  res.render('index', { data: auditInfo });
});


// viewed at http://localhost:3000/getData
/*
app.get('/getData', function (req, res) {
  var check = Users[req.query.name];
  if (check) {
    res.render('user', { name: req.query.name, info: check });
  } else {
    res.send('User does not exist...');
  }
});
*/


/*============================================================
	Here, I read in a file with one line into an array. 
	The values are space delimited.
=============================================================*/

function readAuditLog()
{
  rawdata = fs.readFileSync('example.txt', 'utf8');
  auditInfo = rawdata.split(" ");
}




app.listen(3000, function() {
    console.log('Listening on port 3000');
});
