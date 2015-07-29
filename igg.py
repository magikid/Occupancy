#!/usr/bin/python

import argparse
import sys
import PIL
import urllib2
from lxml import html
from PIL import ImageFont
from PIL import Image
from PIL import ImageDraw

# Set up the argument parser
parser = argparse.ArgumentParser(description='Puts the Indiegogo goal percentage on the wall image')
parser.add_argument('--input-file', help='Input file (image to add overlay to)')
parser.add_argument('--output-file', help='Output file (image that will have overlay added)')

# Parse the args
args = parser.parse_args()

# Make sure that the input file was specified
if args.input_file == None:
  print "[ERROR] No input file specified"
  parser.print_help()
  sys.exit(1)
  
# Make sure that the output file was specified
if args.output_file == None:
  print "[ERROR] No output file specified"
  parser.print_help()
  sys.exit(1)

# Grab both arguments
inputFile = args.input_file
outputFile = args.output_file

# Download the HTML from the Indiegogo page
webpage = urllib2.urlopen('https://www.indiegogo.com/projects/help-unallocated-space-keep-growing#/story').read()
# Parse out the dollar amount that has currently been raised
currency = html.fromstring(webpage).xpath('//span[@class="currency currency-xlarge"]/span/text()')[0]
# Convert the dollar amount to just a number and convert that number to a float
currentAmount = float(currency.replace('$','').replace(',',''))
# Convert the current amount to a percentage of the $10,000 goal
percentage = (currentAmount / 10000.0) * 100

# Open up the input image (should be a picture of the wall)
image = Image.open(inputFile)
# Get the width and height of the image
(width, height) = image.size
# Load up the font that will be used to draw on the image
font = ImageFont.truetype("/usr/share/fonts/dejavu/DejaVuSans.ttf",22)

# Create a handle to draw on the image with
draw = ImageDraw.Draw(image)
# Draw text 200 pixels from the right and halfway down on the image
# The text will be "Indiegogo @ XX%"
# The font will be black (0,0,0)
draw.text((width-200, height/2), "Indiegogo @ %0.0f%%" % percentage, (0, 0, 0), font=font)

# Not sure if these two are actually needed or not
draw = ImageDraw.Draw(image)
draw = ImageDraw.Draw(image)

# Save the output image
image.save(outputFile)
