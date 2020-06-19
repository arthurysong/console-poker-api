import ActionCable from 'actioncable';

export default function cableMiddleware() {
  // const cable = ActionCable.createConsumer(`ws://127.0.0.1:3001/cable?token=${localStorage.getItem('token')}`);
  const cable = ActionCable.createConsumer(`ws://127.0.0.1:3001/cable`);

  return ({ dispatch, getState }) => next => (action) => {
    if (typeof(action) === 'function') {
      return next(action)
    }

    const {
      channel,
      room,
      game,
      leave
    } = action;
    const token = localStorage.getItem('token')
    const identifier = Object.assign({}, action, { token } )

    if (!channel) {
      return next(action);
    }

    if (room) {
      if(leave) {
        const subscription = cable.subscriptions.subscriptions.find(sub => sub.identifier === JSON.stringify({ channel, room, token }))
        cable.subscriptions.remove(subscription);
        dispatch({ type: 'DELETE_ROOM' })
        dispatch({ type: 'CLEAR_MESSAGES' })
        return;
      }

      const received = result => {
        console.log(result)
        switch (result.type) {
            case 'current_room':
              dispatch({ type: 'SET_ROOM', room: result.room });
              break;
            case 'set_game':
              dispatch({ type: 'SET_GAME', game: result.game });
              dispatch({ type: 'SET_STATUS', status: result.game.active_round.status })
              break;
            case 'new_message':
                dispatch({ type: 'NEW_MESSAGE', message: result.message });
                break;
            default:
                break;
        }
      }

      const sendMessage = function(message) {
          this.perform('create_message', {
              content: message
          });
      }

      return cable.subscriptions.create( identifier, { received, sendMessage });
    }

    if (game) {
      if(leave) {
        const subscription = cable.subscriptions.subscriptions.find(sub => sub.identifier === JSON.stringify({ channel, game, token }))
        cable.subscriptions.remove(subscription);
        dispatch({ type: 'DELETE_GAME' })
        return;
      }

      const received = result => {
        console.log(result)
        switch (result.type) {
          case 'update_status':
            console.log(result);
            dispatch({type: 'UPDATE_STATUS', status: result.status })
            break;
          default:
            break;
        }
      }

      return cable.subscriptions.create( identifier, { received });
    }


    
  };
}