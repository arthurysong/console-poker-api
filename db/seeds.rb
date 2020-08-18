# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
marley = User.create({ username: 'Marley', email: 'dog@gmail.com', password: "123456", chips: 100000000 })

room = Room.create(name: 'Play with Marley')
room.users << marley
room.save

game = Game.create(room_id: room.id)
game.sit(nil, marley)
game.save

room2 = Room.create(name: "Let's tilt")
game2 = Game.create(room_id: room2.id)

room3 = Room.create(name: "Flatiron Cash Games")
game3 = Game.create(room_id: room3.id)

room4 = Room.create(name: "Software Engineers")
game4 = Game.create(room_id: room4.id)

room5 = Room.create(name: "EZ Money")
game5 = Game.create(room_id: room5.id)

users = User.create([
    # {username: 'sona', email: 'sona@gmail.com', password: '123456', room: room },
    # {username: 'toxicflower', email: 'toxicflower@gmail.com', password: '123456', room: room },
    # {username: 'phoenixgold', email: 'phoenixgold@gmail.com', password: '123456', room: room },
    # {username: 'fudge', email: 'fudge@gmail.com', password: '123456', room: room },    
    {username: 'sona', email: 'sona@gmail.com', password: '123456', chips: 10000 },
    {username: 'toxicflower', email: 'toxicflower@gmail.com', password: '123456', chips: 10000 },
    {username: 'phoenixgold', email: 'phoenixgold@gmail.com', password: '123456', chips: 10000 },
    {username: 'fudge', email: 'fudge@gmail.com', password: '123456', chips: 10000 },
    {username: 'bulldog', email: 'bulldog@gmail.com', password: '123456' },
    {username: 'raeyei', email: 'raeyei@gmail.com', password: '123456' },
    {username: 'lacari', email: 'lacari@gmail.com', password: '123456' },
    {username: 'arch', email: 'arch@gmail.com', password: '123456' },
    {username: 'drunkenmonkey', email: 'drunkenmonkey@gmail.com', password: '123456' },
    {username: 'warlord', email: 'warlord@gmail.com', password: '123456' },
    {username: 'laden', email: 'laden@gmail.com', password: '123456' },
    {username: 'bruceu', email: 'bruceu@gmail.com', password: '123456' }
])

chatbox = Chatbox.create(room_id: room.id)
chatbox2 = Chatbox.create(room_id: room2.id)

messages = Message.create([
    {chatbox: chatbox, user: users[0], payload: "what's up guys?"},
    {chatbox: chatbox, user: users[1], payload: "yo what up, how you been??"},
    {chatbox: chatbox, user: users[2], payload: "hey guys, wanna play some cs or the forest?"},
    {chatbox: chatbox, user: users[2], payload: "i heard it's pretty good"},
    {chatbox: chatbox, user: users[3], payload: "supppp, i'm down for the forest"}
])



