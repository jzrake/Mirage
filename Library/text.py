import numpy as np
import mirage



state = dict()



def update(event=dict()):
    state['text'] = event.get('Text', "Here you go the text for you!")
    mirage.show(scene("Text quad", text_node(state['text'])))



def controls():
    text_control = mirage.Control(name='Text', control='text', value=state['text']) 
    return [text_control]



if __name__ == "__main__":
    mirage.set_controls_callback(controls)
    mirage.set_event_handler(update)
    update()
