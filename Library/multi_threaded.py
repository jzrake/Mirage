from time import sleep
from threading import Thread, current_thread, main_thread



def myfunc(i):
    print("sleeping 1 sec from thread %d" % i, current_thread() is main_thread())
    sleep(1)
    print("finished sleeping from thread %d" % i)


for i in range(10):
    t = Thread(target=myfunc, args=(i,))
    t.start()


print(current_thread() is main_thread())
print("OK")
