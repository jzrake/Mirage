import sys
import mirage


class _LogWriter:
    def flush(self):
        pass

    def write(self, s):
        mirage.log(s)


sys.stdout = _LogWriter()
sys.stderr = _LogWriter()
