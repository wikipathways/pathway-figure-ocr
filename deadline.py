# see https://filosophy.org/code/python-function-execution-deadlines---in-simple-examples/
# to use, put this line, uncommented, above the function needing a timeout:
#@deadline(20)

import signal


class TimedOutExc(Exception):
    pass

def deadline(timeout, *args):
    def decorate(f):
        def handler(signum, frame):
            raise TimedOutExc()

        def new_f(*args):
            signal.signal(signal.SIGALRM, handler)
            signal.alarm(timeout)
            return f(*args)
            signal.alarm(0)

        new_f.__name__ = f.__name__
        return new_f
    return decorate
