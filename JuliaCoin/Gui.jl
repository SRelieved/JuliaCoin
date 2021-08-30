using PyCall

gui = pyimport("tkinter")

x = gui.Tk()
 
x.geometry("655x330+350+100")

x.title("Jcoinapp")

x.mainloop()

