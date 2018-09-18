import sys
import mirage


class _LogWriter:
    def flush(self):
        pass

    def write(self, s):
        mirage.log(s)


sys.stdout = _LogWriter()
sys.stderr = _LogWriter()
mirage.set_event_handler(lambda d: print(d))


prop_slider = mirage.UserParameter(name='Float', control='slider')
prop_text   = mirage.UserParameter(name='Text', control='text')

test_scene = mirage.Scene('Scene')
test_scene.parameters = [prop_text, prop_slider]
mirage.show(test_scene)
