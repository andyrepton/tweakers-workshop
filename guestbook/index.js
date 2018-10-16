// Define all requirments and properties for this app
const low = require('lowdb')
const FileSync = require('lowdb/adapters/FileSync')

const adapter = new FileSync('db/db.json')
const db = low(adapter)

var mysql = require('mysql');
var express = require('express')

const logger = require('morgan')

const bodyParser = require('body-parser')

//Get env variables
var name = process.env.NAME;
var database = process.env.DATABASE_TYPE;
var killhealth = process.env.KILLHEALTHCHECK;

var app = express()
app.use(logger('dev'))
app.set('views', 'views')
app.set('view engine', 'ejs')
app.use(bodyParser.urlencoded({ extended: false}))

	
	if(database=="mysql"){
		console.log("Using MySQL database!");
		var useddb = "MySQL";
  	}else{
  		console.log("Using file database!");
  		var useddb = "File";
  		//Set defaults in database
		db.defaults({ posts: [], count: 0 })
	  	.write()
  	}


function bootstrap(){
	console.log("Schuberg Philis - Tweakers Guestbook starting!")
	console.log("Information: \n If you want to use the killswitch (for liveness probes) use KILLHEALTHCHECK=true \n If you want to use MySQL as datasbase, use DATABASE_TYPE=mysql \n Set the name of your guestbook with NAME=<name>")
  	//Start Express webserver (if killhealth is not set)
  	if (!killhealth){
	  	var server = app.listen(80, function () {
	  	var host = server.address().address
	  	var port = server.address().port
	  	console.log('Server listening on http://%s:%s', host, port)
		})
  }else{ 
  		console.log("Didn't start webserver because KILLHEALTHCHECK is true! Keepalive set to 60s"); 
  		setInterval(function() { console.log("Exit after keepalive of process"); process.exit() }, 60000);
	}
}


//Mysql
var connection = mysql.createConnection({
	  host: "db",
	  user: "user",
	  password: "password",
	  database: "messages"
	});


//Middleware to send data object back to the frontend
function middleware(req, res, next) {
	if(database != "mysql"){
		var data = db.get('posts')
	     .cloneDeep()
	     .value();
	     res.locals.messages = data;
	     next();
    }
    next();
}
app.use(middleware);

//Express routes handling
app.get('/', (req, res) => {
	//Check if we are using the MySQL Database
	if(database == "mysql"){
		var queryString = 'SELECT * FROM messages';
		//Fetching all the reactions from the database
		connection.query(queryString, function(err, rows, fields) {
	    if (err) throw err;
	 	res.render('index', { name: name, messages: rows, useddb: useddb})
		});
	}else{
		//No MySQL database, just rendering the index
		res.render('index', {name: name, useddb: useddb});
	}
})

//Render the form for an new entry on /new
app.get('/new', (req, res) => {
  res.render('new', { name: name, useddb: useddb})
})

//Handle the post on /new to save the data to the json or MySQL Database
app.post('/new', (req, res) => {
  if (!req.body.name || !req.body.message) {
    res.status(400).send('Name or message empty!')
  }
  if(database != "mysql"){
	db.get('posts')
		.push({message: req.body.message, user: req.body.name})
	 	.write();
	console.log("Post saved to file database!");
  }else{
  	var post  = {user: req.body.name, message: req.body.message};
  	var query = connection.query('INSERT INTO messages SET ?', post, function(err, result) {
  		console.log("Post saved to MySQL database!");
	});
  }
  //Redirect back to the homepage
  res.redirect('/')
})

//Bootstrap the app
bootstrap();

