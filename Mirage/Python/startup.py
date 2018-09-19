import sys
import mirage


class _LogWriter:
    def flush(self):
        pass

    def write(self, s):
        mirage.log(s)


sys.stdout = _LogWriter()
sys.stderr = _LogWriter()

#slider = mirage.Control(name='Float', control='slider', value=0.5)
#text   = mirage.Control(name='Text', control='text', value="value")
#
#mirage.set_controls_callback(lambda: [slider, text])
#mirage.set_event_handler(lambda d: print(d))
#mirage.show(mirage.Scene('Scene'))
