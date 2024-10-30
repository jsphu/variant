def luck():
	import random
	if random.randint(0,10)==0:
		return "good"
	else:
		return "bad"
if __name__ == "__main__":
	luck()
