'''Print the words and their frequencies in this file'''

import operator
import pyspark
import os.path

filename =    'data/pg3200.txt'


def main():
    '''Program entry point'''

    # Intialize a spark context
    with pyspark.SparkContext("local", "PySparkWordCount") as sc:
        # Get a RDD containing lines from this script file
        if os.path.exists(filename):
            lines = sc.textFile(filename)  # same file
        else:
            lines = sc.textFile(__file__)  # original behavior
        # Split each line into words and assign a frequency of 1 to each word
        words = lines.flatMap(lambda line: line.split(" ")).map(
            lambda word: (word.lower().strip('\t\"\' ,.!?;:_-+*'), 1)
        )
        # count the frequency for words
        counts = words.reduceByKey(operator.add)
        # Sort the counts in descending order based on the word frequency
        sorted_counts = counts.sortBy(lambda x: x[1], False)
        # Get an iterator over the counts to print a word and its frequency
        # 		print("Number of words in document:", words.count())
        # 		print("Number of word entries found:", sorted_counts.count())
        for word, count in sorted_counts.toLocalIterator():
            # if count>100 and 0<len(word)<3 :	#	short words
            if count > 400 and len(word) > 2:  # long words
                print(u"{:_<32}\t-->\t{}".format(word, count))


if __name__ == "__main__":
    main()
