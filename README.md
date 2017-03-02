# boPro (Bowen's projects)
Code from my PhD in the Decision Neuroscience Lab.
For all enquiries please contact bowenjfung@gmail.com, but I wouldn't expect much clarification.

The directory is divided into matlab and R code, with some overlaps in terms of the specific projects. 
Generally, stimulus display has been coded in matlab, and analysis is coded in R.
Here is a rough summary of the projects:

### TIMEDEC (7/2012 - 12/2015)
- n = 145 (120 with ECG recording)
- Attempted to relate duration reproduction and temporal discounting
- Found that ECG parameters independently related to temporal discounting and time perception

### TIMEGUESS (pilot, 4/2013)
- n = 19
- Attempted to replicate magnitude/time, and oddball effects using temporal classification task
- Particpants presented with an ‘anchor’ (“About 4 seconds”), then stimulus (dots, circles or lines), after which they classify the stimulus as shorter/longer than the anchor
- Stimulus duration always the same as anchor?
- Unable to replicate oddball or magnitude effects, probably due to intervals used (supra-second)
- Final version is TG24.4 

### WOF (unfinished, 8/2013)
- Temporal bisection task where one stimulus codes the outcome of a gamble
- Intended to investigate the effects of reward valence on time perception

### EDT (5/2013 - 7/2014)
- n = 19 (7 additional participants in pilot)
- Used primary reward (fruit juice) in an experiential discounting task
- Calibrated individual discount rates to bias choices in subsequent test
- Found that participants did not reliably “discount”, and that some appeared to follow a reward maximising strategy that accounted for the ITI
- There are a number of different versions of this paradigm, only the latest of which are in this repo

### Blink Bandit (BB) (7/2013)
- The auditory bandit task Dan Bennett and I ran for the neuroeconomics grad subject
- Tried to show a relationship between spontaneous blink rate (tonic DA) and exploration/exploitation
- Promising, but unfinished

### Juice space (3/2014 - 4/2014)
- n = 7 (4 sessions each)
- Used staircase algorithms (QUEST and Psi) to determine juice volume discrimination (75% detection)
- Found a weber fraction of ~0.5 for two different volumes (0.5 & 3 mL)
- Poor programming led to data being too big to store anywhere really
  
### Juice value (5/2014)
- n = 5
- Acquired thirst, pleasantness and satiety ratings for different volumes of juice
- Found power relationship between volume and pleasantness

### PIP (7/2014 - 5/2015)
- n = 75
- Used half-peak interval procedure with different rewards (juice, money, water)
- Found an effect of fruit juice on response timing
- Various versions of this correspond to the juice, money and water versions of the task (v3 is juice)

### FIP (unfinished, 5/2015)
- Attempted to show time/juice effect on behavioural foraging choices
- Modelling showed only a marginal, non-measureable effect on choices

### QT (6/2015 - 8/2015)
- n = 50
- Used waiting/persistence task with primary rewards
- Found that water condition waited longer than glucose/aspartame condition

### PPP (12/2015 - 2/2016)
- n = 50
- Used PIP task with additional physiological measures (ECG, EOG, GSR)
- Attempt to show that physiological changes due to calorie intake mediate changes in time perception
- Marginally significant effect of maltodextrin, but no effect of aspartame
- Apparent correlation between HRV and the underestimation between task phases corresponding to liquid consumption

