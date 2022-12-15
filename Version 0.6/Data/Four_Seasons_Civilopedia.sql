-- ===========================================================================
-- Four_Seasons_Civilopedia
-- Author: sharpNd
-- 2022-12-03
-- Version 0.5.1
-- ===========================================================================


-- ===========================================================================
-- CivilopediaPageGroups
-- ===========================================================================
INSERT OR REPLACE INTO CivilopediaPageGroups
		(SectionID,		PageGroupId,		SortIndex,		VisibleIfEmpty,		Tooltip,	Name)
VALUES	('CONCEPTS',	'FOUR_SEASONS',		5,				0,					'',			'LOC_PEDIA_CONCEPTS_PAGEGROUP_FOUR_SEASONS_NAME');


-- ===========================================================================
-- CivilopediaPages
-- ===========================================================================
INSERT OR REPLACE INTO CivilopediaPages
		(SectionId,		PageId,							PageGroupId,		SortIndex,		PageLayoutId,		Tooltip,	Name)
VALUES	('CONCEPTS',	'FOUR_SEASONS_INTRODUCTION',	'FOUR_SEASONS',		10,				'Introduction',		'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_INTRODUCTION_TITLE'),

        ('CONCEPTS',	'FOUR_SEASONS_EFFECTS',			'FOUR_SEASONS',		20,				'Effects',			'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_EFFECTS_TITLE'),
		('CONCEPTS',	'FOUR_SEASONS_INTENSITY',		'FOUR_SEASONS',		30,				'Intensity',			'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_INTENSITY_TITLE'),
		('CONCEPTS',	'FOUR_SEASONS_SEASONLENGTH',	'FOUR_SEASONS',		40,				'SeasonLength',		'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_SEASONLENGTH_TITLE'),
		('CONCEPTS',	'FOUR_SEASONS_OFFSETS',			'FOUR_SEASONS',		50,				'Offsets',			'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_OFFSETS_TITLE'),
		('CONCEPTS',	'FOUR_SEASONS_VISUALS',			'FOUR_SEASONS',		60,				'Visuals',			'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_VISUALS_TITLE'), 
		
		('CONCEPTS',	'FOUR_SEASONS_SUMMER',			'FOUR_SEASONS',		70,				'Summer',			'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_SUMMER_TITLE'),
		('CONCEPTS',	'FOUR_SEASONS_AUTUMN',			'FOUR_SEASONS',		80,				'Autumn',	    	'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_AUTUMN_TITLE'),
		('CONCEPTS',	'FOUR_SEASONS_WINTER',			'FOUR_SEASONS',		90,				'Winter',	   	 	'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_WINTER_TITLE'),
		('CONCEPTS',	'FOUR_SEASONS_SPRING',			'FOUR_SEASONS',		100,			'Spring',	    	'',			'LOC_PEDIA_CONCEPTS_PAGE_FOUR_SEASONS_SPRING_TITLE');


-- ===========================================================================
-- CivilopediaPageLayouts
-- ===========================================================================
INSERT OR REPLACE INTO CivilopediaPageLayouts
(PageLayoutId,		ScriptTemplate) VALUES	
('Introduction',	'Simple'),

('Effects',			'Simple'),
('Intensity',		'Simple'),
('SeasonLength',	'Simple'),
('Offsets',			'Simple'),
('Visuals',			'Simple'),

('Summer',			'Simple'),
('Autumn',	    	'Simple'),
('Winter',	        'Simple'),
('Spring',	        'Simple');


-- ===========================================================================
-- CivilopediaPageLayoutChapters
-- ===========================================================================
INSERT OR REPLACE INTO CivilopediaPageLayoutChapters
(PageLayoutId,		ChapterId,		SortIndex)	VALUES	
('Introduction',	'INTRO',		10),
('Introduction',	'SUMMARY',		20),
('Introduction',	'INSPIRATION',	30),
('Introduction',	'CREDIT',		40),

('Effects',			'CONTENT',		10),
('Intensity',		'CONTENT',		10),
('SeasonLength',	'CONTENT',		10),
('Offsets',			'CONTENT',		10),
('Visuals',			'CONTENT',		10),

('Summer',			'BASE',			10),
('Summer',			'INTENSITY1',	20),
('Summer',			'INTENSITY2',	30),
('Summer',			'INTENSITY3',	40),
('Summer',			'INTENSITY4',	50),
('Summer',			'INTENSITY5',	60),

('Autumn',			'BASE',			10),
('Autumn',			'INTENSITY1',	20),
('Autumn',			'INTENSITY2',	30),
('Autumn',			'INTENSITY3',	40),
('Autumn',			'INTENSITY4',	50),
('Autumn',			'INTENSITY5',	60),

('Winter',			'BASE',			10),
('Winter',			'INTENSITY1',	20),
('Winter',			'INTENSITY2',	30),
('Winter',			'INTENSITY3',	40),
('Winter',			'INTENSITY4',	50),
('Winter',			'INTENSITY5',	60),
('Winter',			'INTENSITY6',	70),

('Spring',			'BASE',			10),
('Spring',			'INTENSITY1',	20),
('Spring',			'INTENSITY2',	30),
('Spring',			'INTENSITY3',	40),
('Spring',			'INTENSITY4',	50),
('Spring',			'INTENSITY5',	60);