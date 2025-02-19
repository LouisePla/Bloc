Class {
	#name : #BATextMeasurer,
	#superclass : #BlHostTextMeasurer,
	#instVars : [
		'lineAdvance'
	],
	#category : #'Bloc-Alexandrie-Text'
}

{ #category : #accessing }
BATextMeasurer >> canvas [

	^ self subclassResponsibility
]

{ #category : #dispatch }
BATextMeasurer >> measureTextParagraph: aBlTextParagraph [

	aBlTextParagraph measureOn: self
]

{ #category : #measurement }
BATextMeasurer >> measureTextSpan: aBlSpan [

	"Measure a given text span and return paragraph span with computed metrics"
	^ self createParagraphSpan setupFromHostTextMeasurer: self forSpan: aBlSpan
]

{ #category : #'paragraph span instance creation' }
BATextMeasurer >> newParagraphSpan [
	^ BATextParagraphSpan new
]
