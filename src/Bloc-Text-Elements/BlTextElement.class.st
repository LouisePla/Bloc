"
# Text element

I support multiple measurement strategies. See examples for more detailed explanation on:
`BlTextElementMeasurementStrategyExamples`.


"
Class {
	#name : #BlTextElement,
	#superclass : #BlElement,
	#instVars : [
		'text',
		'paragraph',
		'selection',
		'measurement',
		'measurer',
		'defaultFontSize',
		'baselineMeasurer',
		'highlightsMap',
		'fillSize',
		'tabOffset'
	],
	#classVars : [
		'DefaultText',
		'SelectionMatchParent'
	],
	#category : #'Bloc-Text-Elements'
}

{ #category : #'class initialization' }
BlTextElement class >> initialize [ 
	DefaultText := 'Text' asRopedText readonly
]

{ #category : #accessing }
BlTextElement class >> selectionColor [

	^ Color
		  r: 0.9530791788856305
		  g: 0.8084066471163245
		  b: 0.1906158357771261
		  alpha: 1.0
]

{ #category : #accessing }
BlTextElement class >> selectionMatchParent [
	^ SelectionMatchParent ifNil: [ SelectionMatchParent := false ] 
]

{ #category : #accessing }
BlTextElement class >> selectionMatchParent: aBoolean [
	SelectionMatchParent := aBoolean
]

{ #category : #'instance creation' }
BlTextElement class >> text: aBlText [

	^ self new
		  text: aBlText;
		  yourself
]

{ #category : #accessing }
BlTextElement >> baseline [

	self
		deprecated: 'Please use baselineMeasurer instead.'
		transformWith:
			'`@receiver baseline'
				-> '`@receiver baselineMeasurer'.
	
	^ self baselineMeasurer
]

{ #category : #accessing }
BlTextElement >> baselineMeasurer [
	
	^ baselineMeasurer
]

{ #category : #accessing }
BlTextElement >> baselineMeasurer: aBlTextParagraphBaselineMeasurer [

	baselineMeasurer := aBlTextParagraphBaselineMeasurer.
	self textChanged
]

{ #category : #layout }
BlTextElement >> baselineOffset [
	^ paragraph
		ifNotNil: [ paragraph baseline y + self padding top ]
		ifNil: [ 0 ]
]

{ #category : #layout }
BlTextElement >> basicMeasureParagraph: aBlTextParagraph [
	measurer measureTextParagraph: aBlTextParagraph of: self
]

{ #category : #'paragraph - geometry' }
BlTextElement >> characterBoundsAtIndex: aLocalIndex [

	| startSpan startPos originIdx endPos endSpan cornerIdx extentToUse |
	extentToUse := fillSize ifNil: [ self extent ] ifNotNil: [ (fillSize max: self extent x) @ self extent y ].
	originIdx := (aLocalIndex - 1 max: 0) min: text size.
	startSpan := paragraph spanAtIndex: originIdx.
	startPos := startSpan positionAt: originIdx.

	cornerIdx := originIdx + 1 min: text size.
	endSpan := paragraph spanAtIndex: cornerIdx.
	endPos := endSpan positionAt: cornerIdx.
	^ startPos x @ 0 corner: endPos x @ extentToUse y
]

{ #category : #layout }
BlTextElement >> computeMaxHeight: anExtentMeasurementSpec [
	<return: #Number>
	| aMaxHeight aHeightSpec aPadding |

	aMaxHeight := self constraints maxHeight.
	aHeightSpec := anExtentMeasurementSpec heightSpec.
	aPadding := self constraints padding.
	
	aHeightSpec isUnspecified
		ifFalse: [ aMaxHeight := aMaxHeight min: aHeightSpec size ].

	aMaxHeight := (aMaxHeight - aPadding height) max: 0.
	
	^ aMaxHeight
]

{ #category : #layout }
BlTextElement >> computeMaxWidth: anExtentMeasurementSpec [
	<return: #Number>
	| aMaxWidth aWidthSpec aPadding |

	aMaxWidth := self constraints maxWidth.
	aWidthSpec := anExtentMeasurementSpec widthSpec.
	aPadding := self constraints padding.
	
	"Unspecified means that layout may take as much space horizontally as it wishes"
	aWidthSpec isUnspecified
		ifFalse: [ aMaxWidth := aMaxWidth min: aWidthSpec size ].

	aMaxWidth := (aMaxWidth - aPadding width) max: 0.
	
	^ aMaxWidth
]

{ #category : #'private - paragraph' }
BlTextElement >> createTextParagraph [
	"Create a text paragraph used to measure and render text"

	^ BlTextParagraph new 
]

{ #category : #'api - font size' }
BlTextElement >> defaultFontSize: aNumber [	
	defaultFontSize = aNumber
		ifTrue: [ ^ self ].

	defaultFontSize := aNumber.
	
	self text defaultFontSize: aNumber.
	self textChanged
]

{ #category : #'api - highlighting' }
BlTextElement >> defaultHighlightCategory [

	^ #default
]

{ #category : #initialization }
BlTextElement >> defaultMeasurer [
	^ BlTextElementHostMeasurer uniqueInstance 
]

{ #category : #initialization }
BlTextElement >> defaultText [
	"Return a default text I should be created with"
	<return: #BlText>

	^ DefaultText
]

{ #category : #'selection - management' }
BlTextElement >> deselect: aFromIndex to: aToIndex [

	self selection
		deselect: aFromIndex
		to: aToIndex.

	self invalidate
]

{ #category : #'api - text' }
BlTextElement >> editorMeasurement [

	self measurement: BlTextElementEditorMeasurementStrategy uniqueInstance.
	self baselineMeasurer: BlAscentLooseBaselineMeasurer uniqueInstance
]

{ #category : #'selection - management' }
BlTextElement >> hasSelection [
	^ self selection isNotEmpty
]

{ #category : #'api - highlighting' }
BlTextElement >> highlightCategory: aHighlightCategorySymbol with: aParagraphHighlight [ 

	| l |
	l := self highlightsMap at: aHighlightCategorySymbol ifAbsentPut: [OrderedCollection new].
	l add: aParagraphHighlight.
	self invalidate
]

{ #category : #'api - highlighting' }
BlTextElement >> highlightRectanglesOfCategory: aCategory [

	^ Array streamContents: [ :stream | 
		  (self highlightsOfCategory: aCategory) do: [ :eachHighlight | 
			  stream nextPutAll:
				  (self selectionRectanglesFrom: eachHighlight selection) ] ]
]

{ #category : #'api - highlighting' }
BlTextElement >> highlightWith: aParagraphHighlight [ 

	self highlightCategory: self defaultHighlightCategory with: aParagraphHighlight. 

]

{ #category : #'api - highlighting' }
BlTextElement >> highlights [

	^ highlightsMap ifNotNil: [ :map | 
		  Array streamContents: [ :stream | map valuesDo: [ :v | stream nextPutAll: v ] ] ]
]

{ #category : #'api - highlighting' }
BlTextElement >> highlightsMap [

	^ highlightsMap ifNil: [ highlightsMap := IdentityDictionary new ]
]

{ #category : #'api - highlighting' }
BlTextElement >> highlightsOfCategory: aCategory [

	^ highlightsMap
		  ifNotNil: [ :map | map at: aCategory ifAbsent: [ #(  ) ] ]
		  ifNil: [ #(  ) ]
]

{ #category : #geometry }
BlTextElement >> indexAtScreenPosition: aPoint [
	<return: #Number>

	^ self paragraph indexAtPosition: aPoint - self padding topLeft
]

{ #category : #initialization }
BlTextElement >> initialize [
	super initialize.

	self tightMeasurement.

	tabOffset := 0.
	text := self defaultText.
	"Text layout is created during measurement in onMeasure:"
	measurer := self defaultMeasurer.

	self constraintsDo: [ :c | 
		c horizontal fitContent.
		c vertical fitContent ].

	selection := BlCompositeSelection new.

	"self debug: true"
]

{ #category : #layout }
BlTextElement >> isTabulation [ 
	^ text isNotEmpty and: [ text first = Character tab ]
]

{ #category : #'api - text' }
BlTextElement >> labelMeasurement [

	self measurement: BlTextElementEditorMeasurementStrategy uniqueInstance.
	self baselineMeasurer: BlAscentTightBaselineMeasurer uniqueInstance
]

{ #category : #layout }
BlTextElement >> measureChildren: anExtentMeasurementSpec [	
	self layout measuredChildren: self do: [ :aChild |
		| aWidthResizer aHeightResizer aWidthSpec aHeightSpec  |
		
		aWidthResizer := aChild constraints horizontal resizer.
		aHeightResizer := aChild constraints vertical resizer.
		
		aWidthResizer isMatchParent
			ifTrue: [ aWidthSpec := BlMeasurementSpec exact: self measuredWidth ]
			ifFalse: [ aWidthSpec := self layout
				measurementSpecFor: anExtentMeasurementSpec widthSpec
				usedSize: 0.0
				resizer: aWidthResizer ].

		aHeightResizer isMatchParent
			ifTrue: [ aHeightSpec := BlMeasurementSpec exact: self measuredHeight ]
			ifFalse: [ aHeightSpec := self layout
				measurementSpecFor: anExtentMeasurementSpec heightSpec
				usedSize: 0.0
				resizer: aHeightResizer ].
	
		aChild measure: aWidthSpec @ aHeightSpec ].
	
	self layout measureIgnored: self with: anExtentMeasurementSpec
]

{ #category : #layout }
BlTextElement >> measuredExtent: anExtentPoint [

	super measuredExtent: (self isTabulation
			 ifTrue: [ self tunedTabulationExtentFrom: anExtentPoint ]
			 ifFalse: [ anExtentPoint ])
]

{ #category : #accessing }
BlTextElement >> measurement [
	<return: #BlTextElementMeasurementStrategy>

	^ measurement
]

{ #category : #accessing }
BlTextElement >> measurement: aTextElementMeasurementStrategy [
	measurement := aTextElementMeasurementStrategy.
	self textChanged
]

{ #category : #accessing }
BlTextElement >> measurer [
	^ measurer
]

{ #category : #accessing }
BlTextElement >> measurer: anObject [
	measurer := anObject.
	self textChanged
]

{ #category : #layout }
BlTextElement >> offsetFromSegmentStart [
	"computed and set during layout by AlbLineFlowLayout>>measure: with: "
	^ self textFlow offsetFromSegmentStart
]

{ #category : #'hooks - session' }
BlTextElement >> onAddedToSceneGraph [
	super onAddedToSceneGraph.
	
	paragraph
		ifNil: [ ^ self ].
		
	paragraph session == Smalltalk session
		ifFalse: [ self textChanged ]
]

{ #category : #layout }
BlTextElement >> onMeasure: anExtentMeasurementSpec [

	"Do the measuring job"

	"fillSize is used to ensure that the selection works with tabulation. 
	In case of a tabulation, it is computed in #tunedTabulationExtentFrom:"

	fillSize := 0.

	self onParagraphMeasure: anExtentMeasurementSpec.
	self onPostMeasure: anExtentMeasurementSpec.
	self measureChildren: anExtentMeasurementSpec
]

{ #category : #layout }
BlTextElement >> onParagraphMeasure: anExtentMeasurementSpec [

	"If I am executed it means that measurement specification changed.
	We have to recreate a text layout with new parameters"

	| aMaxWidth aMaxHeight aWidthSpec aHeightSpec aPadding |
	aWidthSpec := anExtentMeasurementSpec widthSpec.
	aHeightSpec := anExtentMeasurementSpec heightSpec.
	aPadding := self constraints padding.

	aMaxWidth := self computeMaxWidth: anExtentMeasurementSpec.
	aMaxHeight := self computeMaxHeight: anExtentMeasurementSpec.

	paragraph := self createTextParagraph.

	"Create a new text layout"
	paragraph
		text: self text;
		baselineMeasurer: self baselineMeasurer;
		maxWidth: aMaxWidth;
		maxHeight: aMaxHeight;
		scale: self globalScale.

	self basicMeasureParagraph: paragraph.
	"Pay attention that #onPostMeasure: must be send after #onParagraphMeasure:"
]

{ #category : #layout }
BlTextElement >> onPostMeasure: anExtentMeasurementSpec [

	"If I am executed it means that measurement specification changed.
	We have to recreate a text layout with new parameters"

	| measuredWidth measuredHeight maxWidth maxHeight widthSpec heightSpec padding |
	"text layout is measured at this point, complete with TextElement aspects"
	maxWidth := self computeMaxWidth: anExtentMeasurementSpec.
	maxHeight := self computeMaxHeight: anExtentMeasurementSpec.
	widthSpec := anExtentMeasurementSpec widthSpec.
	heightSpec := anExtentMeasurementSpec heightSpec.
	padding := self constraints padding.
	(measurement boundsOf: paragraph) in: [ :bnds | 
		measuredWidth := bnds width min: maxWidth.
		measuredHeight := bnds height min: maxHeight ].

	"If measurement spec is exact I must ignore size measured by textLayout"
	widthSpec isExact ifTrue: [ measuredWidth := widthSpec size ].
	heightSpec isExact ifTrue: [ measuredHeight := heightSpec size ].

	"Take minimal width and height into account"
	measuredWidth := measuredWidth max: self constraints minWidth - padding width.
	measuredHeight := measuredHeight max: self constraints minHeight - padding height.
	"Take padding into account to finally set measured extent"
	self measuredExtent: measuredWidth @ measuredHeight + (padding width @ padding height)
]

{ #category : #'hooks - session' }
BlTextElement >> onSessionChanged: aNewSession [
	super onSessionChanged: aNewSession.
	
	self textChanged
]

{ #category : #'private - paragraph' }
BlTextElement >> paragraph [

	^ paragraph
]

{ #category : #accessing }
BlTextElement >> rawParagraph [

	self
		deprecated: 'Please use paragraph instead.'
		transformWith:
			'`@receiver rawParagraph'
				-> '`@receiver paragraph'.
	
	^ self paragraph
]

{ #category : #'private - paragraph' }
BlTextElement >> releaseParagraph [
	paragraph := nil
]

{ #category : #'api - font size' }
BlTextElement >> resetDefaultFontSize [
	defaultFontSize := nil
]

{ #category : #'api - highlighting' }
BlTextElement >> resetHighlightsMap [

	highlightsMap := nil.
	self invalidate
]

{ #category : #'api - highlighting' }
BlTextElement >> resetHighlightsOfCategory: aHighlightCategorySymbol [

	highlightsMap ifNil: [ ^self ].
	highlightsMap removeKey: aHighlightCategorySymbol ifAbsent: [^self].
	self invalidate
]

{ #category : #geometry }
BlTextElement >> screenCornerAt: aTextIndex [

	<return: #Point>
	| aScreenPosition |
	aScreenPosition := self paragraph positionAt: aTextIndex.
	^ aScreenPosition x - self padding right @ (self height - self padding height)
]

{ #category : #geometry }
BlTextElement >> screenOriginAt: aTextIndex [

	<return: #Point>
	| aScreenPosition |
	aScreenPosition := self paragraph positionAt: (aTextIndex max: 0).
	^ aScreenPosition x + self padding left @ self padding height
]

{ #category : #geometry }
BlTextElement >> screenPositionAt: aTextIndex [
	<return: #Point>
	| aScreenPosition |
	
	aScreenPosition := self paragraph positionAt: aTextIndex.
	^ (aScreenPosition x + self padding left) @ ((self height + self padding height) / 2.0)
]

{ #category : #'selection - management' }
BlTextElement >> select: aFromIndex to: aToIndex [

	self selection
		select: aFromIndex
		to: aToIndex.

	self invalidate
]

{ #category : #'selection - management' }
BlTextElement >> selectNone [
	self selection isEmpty
		ifTrue: [ ^ self ].
	self selection removeAll.
	self invalidate
]

{ #category : #'selection - management' }
BlTextElement >> selectSet: aFromIndex to: aToIndex [

	self selection
		removeAll;
		select: aFromIndex
		to: aToIndex.

	self invalidate
]

{ #category : #'selection - management' }
BlTextElement >> selection [
	<return: #BlSelection>
	
	self
		assert: [ selection isNotNil ]
		description: [ 'Selection can not be nil' ].

	^ selection
]

{ #category : #geometry }
BlTextElement >> selectionRectangles [

	^ self selectionRectanglesFrom: selection
]

{ #category : #geometry }
BlTextElement >> selectionRectanglesFrom: aSelection [

	| extentToUse origin cornerY |
	(aSelection isNil or: [ aSelection isEmpty ]) ifTrue: [ ^ #(  ) ].
	origin := self textFlow assignedLine origin.
	cornerY := origin y + self textFlow assignedLine height.
	extentToUse :=  (fillSize max: self extent x) @ cornerY.
	^ Array streamContents: [ :stream | 
		  aSelection do: [ :currSelection | 
			  | aStart anEnd aSelectionStartSpan aSelectionEndSpan aSelectionStartPosition aSelectionEndPosition |
			  aStart := currSelection from min: text size.
			  anEnd := currSelection to min: text size.

			  aSelectionStartSpan := paragraph spanAtIndex: aStart.
			  aSelectionEndSpan := paragraph spanAtIndex: anEnd.

			  aSelectionStartPosition := aStart isZero
				                             ifTrue: [ 0 @ origin y ]
				                             ifFalse: [ (aSelectionStartSpan positionAt: aStart) + (self padding left @ origin y) ].

			  aSelectionEndPosition := anEnd = text size
				                           ifTrue: [ (aSelectionEndSpan positionAt: anEnd) + (self padding width - tabOffset @ cornerY) ]
				                           ifFalse: [ (aSelectionEndSpan positionAt: anEnd) + (self padding left - tabOffset @ cornerY) ].

			  "containerExtent includes padding"
			  stream nextPut: (currSelection to > text size
					   ifTrue: [ aSelectionStartPosition x @ origin y corner: extentToUse ]
					   ifFalse: [ aSelectionStartPosition x @ origin y corner: aSelectionEndPosition x @ extentToUse y ]) ] ]
]

{ #category : #layout }
BlTextElement >> supportsBaseline [
	<return: #Boolean>

	^ true
]

{ #category : #accessing }
BlTextElement >> text [
	"Return the text I currently represent.
	Note, that I work with immutable text (BlText), so if you want to change or style text
	you have to set manually sending #text: message with new styled text model"
	
	^ text
]

{ #category : #accessing }
BlTextElement >> text: aBlText [
	"Change a text I represent"
	text = aBlText ifTrue: [ ^ self ].
	text := aBlText.
	defaultFontSize ifNotNil: [ :aDefaultFontSize | text defaultFontSize: aDefaultFontSize ].
	self textChanged
]

{ #category : #'change reporting' }
BlTextElement >> textChanged [
	"text layout is no more valid, remove it"
	self releaseParagraph.

	"request redraw and layout"
	self requestLayout.
	self invalidate
]

{ #category : #accessing }
BlTextElement >> textDo: aBlock [
	"Perform a given block with my current text model as an argument and invalidate text"
	aBlock value: self text.
	self textChanged
]

{ #category : #layout }
BlTextElement >> textFlow [
	^ self constraints albumTextFlow.
]

{ #category : #'api - text' }
BlTextElement >> tightMeasurement [

	self measurement: BlTextElementTightMeasurementStrategy uniqueInstance.
	self baselineMeasurer: BlBoundsBaselineMeasurer uniqueInstance
]

{ #category : #layout }
BlTextElement >> tunedTabulationExtentFrom: anExtentPoint [

	"Computed the size of a tabulation according to the tab-stop size."
	
	"record the fill size for the selection to work in case of #shouldFillLine answers true"
	fillSize := anExtentPoint x.
	"compute and record the offset used to draw the selection on a tab"
	tabOffset := self offsetFromSegmentStart \\ paragraph advance.
	"adapt the extent to correctly measure a tab according to the tab-stop"
	^ paragraph advance - tabOffset @ anExtentPoint y
]
