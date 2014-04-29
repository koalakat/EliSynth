#define KNOB1  0
#define KNOB2  1

#define BUTTON1  2
#define BUTTON2  3
#define BUTTON3  4

#define STAT1  7
#define STAT2  6

#define OFF 1
#define ON 2
#define WAIT 3

#define NULL 255

// midi control message codes
#define NOTE_ON 0x90
#define NOTE_OFF 0x80
#define AFTER_TOUCH 0xA0
#define CONTROL_CHANGE 0xB0
#define PATCH_CHANGE 0xC0
#define CHANNEL_PRESSURE 0xD0
#define PITCH_WHEEL 0xE0

#define NOTE_QUEUE_LENGTH 64

// button 2 note functions
enum note_functions {
  single_note,
  three_note_chord,
  three_note_arpeggio,
  three_note_random
};

// button 1 control modes
enum control_modes {
  base_octave_mode,
  note_range_mode,
  mode_set,
  velocity_mode,
  pitch_wheel,
  tempo_mode,
  repeat_note,
  duration_mode,
  key_set,
  time_signature_mode
};

// repeat
enum repeats {
  repeat_mode,
  no_repeat_mode
};

// modes
enum modes {
  ionian,
  dorian,
  phrygian,
  lydian,
  mixolydian,
  aeolian,
  locrian
};

// note durations
enum note_durations {
  quarter,
  half,
  whole,
  eighth,
  sixteenth,
  thirty_second,
  quarter_triplet,
  eigth_triplet,
  sixteenth_triplet,
  thirty_second_triplet
};

// keys
enum keys {
  c,
  c_sharp_d_flat,
  d,
  d_sharp_e_flat,
  e,
  f,
  f_sharp_g_flat,
  g,
  g_sharp_a_flat,
  a,
  a_sharp_b_flat,
  b
};

enum time_signatures  {
  four_four,
  three_four,
  two_four  
};


char ioanianEncoding[8] = {0, 2, 4, 5, 7, 9, 11, 12};
char dorianEncoding[8] = {0, 2, 3, 5, 7, 9, 10, 12};
char phrygianEncoding[8] = {0, 1, 3, 5, 7, 8, 10, 12};
char lydianEncoding[8] = {0, 2, 4, 6, 7, 9, 11, 12};
char mixolyidianEncoding[8] = {0, 2, 4, 5, 7, 9, 10, 12};
char aeolianEncoding[8] = {0, 2, 3, 5, 7, 8, 10, 12};
char locrianEncoding[8] = {0, 1, 3, 5, 6, 8, 10, 12};

enum scaleNotes
{
  noteI,
  noteII,
  noteIII,
  noteIV,
  noteV,
  noteVI,
  noteVII,
  rest
};

struct noteEvent
{
  scaleNotes note;
  char velocity;
  long time;
  char next;
  char prev;
  bool inUse;
  char noteType; 
  char id;
};

noteEvent noteQueue[NOTE_QUEUE_LENGTH];

struct notePattern
{
  char length;
  scaleNotes notes[32];
};

char firstNote = NULL;



