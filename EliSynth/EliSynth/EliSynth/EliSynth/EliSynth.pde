#include <LiquidCrystal.h>
#include "EliSynth.h"

control_modes control_mode;
int base_octave;      // valid values:  0-8
int note_range;       // valid values:  1-4 octaves
note_functions note_function;    
int note_offset;      
int velocity;         // valid values:  1-127
int tempo;             // valid values:  20-300 bpm
int pitch_bend;        // valid values:  0-16384 cents
modes mode;
byte repeat;
note_durations note_duration;
keys base_key;
time_signatures time_signature;

int note;

int knob1;
int knob2;

boolean button1 = false;
boolean button2 = false;
boolean button3 = false;
boolean button1LastReading = false;
boolean button2LastReading = false;
boolean button3LastReading = false;
int buttonDebounceRate = 50;

String headerString = "EliSynth v0.1 ";
String baseOctaveString = "Base Octave: ";
String noteRangeString = "Note Range: ";
String modeString = "Mode: ";
String velocityString = "Velocity: ";
String durationString = "Duration: ";
String pitchBendString = "Pitch Bend: ";
String tempoString = "Tempo: ";
String repeatString = "Repeat: ";
String noteFunctionString = "Func: ";
String timeSignatureString = "Time: ";
String keyString = "Key: ";
String spacesString = "     ";
long lastDisplayUpdateTime = 0;
int displayUpdateRate = 500;  // interval in ms between dispay updates

LiquidCrystal lcd(5,8,9,10,11,12);

notePattern singleNote;
notePattern threeChord;
notePattern threeArpeggio;

  

void setup() {
  
  lcd.begin (16,4);
  
  pinMode(STAT1,OUTPUT);   
  pinMode(STAT2,OUTPUT);

  pinMode(BUTTON1,INPUT);
  pinMode(BUTTON2,INPUT);
  pinMode(BUTTON3,INPUT);

  digitalWrite(BUTTON1,HIGH);
  digitalWrite(BUTTON2,HIGH);
  digitalWrite(BUTTON3,HIGH);

  digitalWrite(STAT1,HIGH);   
  digitalWrite(STAT2,HIGH);

  //start serial with midi baudrate 31250
  Serial.begin(31250);

  // initialize note parameters
  control_mode = base_octave_mode;
  base_octave = 4;
  note_range = 2;
  note_function = single_note;
  note_offset = 0;
  velocity = 64;
  tempo = 120;
  pitch_bend = 0;
  mode = ionian;
  repeat = no_repeat_mode;
  note_duration = quarter;
  base_key = c;
  time_signature = four_four;
  note = (base_octave * 12) + 12 + base_key;
  
  // create note patterns
  singleNote.length = 1;
  singleNote.notes[0] = noteI;
  
  threeChord.length = 3;
  threeChord.notes[0] = noteI;
  threeChord.notes[1] = noteIII;
  threeChord.notes[2] = noteV;
  
  threeArpeggio.length = 6;
  threeArpeggio.notes[0] = noteI;
  threeArpeggio.notes[1] = rest;
  threeArpeggio.notes[2] = noteIII;
  threeArpeggio.notes[3] = rest;
  threeArpeggio.notes[4] = noteV;
  threeArpeggio.notes[5] = rest;  
  
  // initialize note queue
  for (int i = 0; i < NOTE_QUEUE_LENGTH; i++)
  {
    noteQueue[i].note = noteI;
    noteQueue[i].velocity = 64;
    noteQueue[i].time = 0;
    noteQueue[i].next = 0;
    noteQueue[i].prev = 0;
    noteQueue[i].inUse = false;
    noteQueue[i].noteType = NOTE_ON;
    noteQueue[i].id = i;
  }
}

boolean buttonReading;

void loop () {

  updateDisplay();

  knob1 = analogRead(KNOB1);
  knob2 = analogRead(KNOB2);

  buttonReading = !(digitalRead(BUTTON1));
  if ((buttonReading == true) && (button1LastReading == false))
  {
    button1 = true;
  }
  
  else
  {
    button1 = false;
  }
  
  button1LastReading = buttonReading;
  
  buttonReading = !(digitalRead(BUTTON2));
  if ((buttonReading == true) && (button2LastReading == false))
  {
    button2 = true;
  }
  else
  {
    button2 = false;
  }
  
  button2LastReading = buttonReading;
  
  // process button 1 (control mode)
  if (button1)
  {
    switch (control_mode)
    {
      case base_octave_mode:   control_mode = note_range_mode;       break;
      case note_range_mode:    control_mode = mode_set;              break;
      case mode_set:           control_mode = velocity_mode;         break;
      case velocity_mode:      control_mode = pitch_wheel;           break;
      case pitch_wheel:        control_mode = tempo_mode;            break;
      case tempo_mode:         control_mode = repeat_note;           break;
      case repeat_note:        control_mode = duration_mode;         break;
      case duration_mode:      control_mode = key_set;               break;
      case key_set:            control_mode = time_signature_mode;   break;
      case time_signature_mode: control_mode = base_octave_mode;     break; 
      
    }
  }
  
  // process button 2 (note function)
  
  if (button2)
  {
    switch (note_function)
    {
      case single_note:         note_function = three_note_chord;     break;
      case three_note_chord:    note_function = three_note_arpeggio;  break;
      case three_note_arpeggio: note_function = three_note_random;    break;
      case three_note_random:   note_function = single_note;          break;
    }
  }
  
  int temp = 0;    
  // process knob 1 (control mode)
  switch (control_mode)
  {
      case base_octave_mode:
        base_octave = (knob1 * 9) / 1024;      
        break;
        
      case note_range_mode:
        note_range = ((knob1 * 4) / 1024) + 1;    
        break;
        
      case mode_set:
        temp = (knob1 * 7) / 1024;
        switch (temp)
        {
          case 0:  mode = ionian;      break;
          case 1:  mode = dorian;      break;
          case 2:  mode = phrygian;    break;
          case 3:  mode = lydian;      break;
          case 4:  mode = mixolydian;    break;
          case 5:  mode = aeolian;      break;
          case 6:  mode = locrian;      break;
        }   
        break;
        
      case velocity_mode:
        velocity = (knob1 * 128) / 1024;       
        break;
        
      case pitch_wheel:
        pitch_bend = (knob1 * 128) / 1024; 
        break;
        
      case tempo_mode:
        tempo = (((long)knob1 * 280) / 1024) + 21;      
        break;
        
      case repeat_note:
        temp = (knob1 * 2) / 1024; 
        switch (temp)
        {
          case 0:  repeat = repeat_mode;      break;
          case 1:  repeat = no_repeat_mode;      break;
        }      
        break;
        
      case duration_mode:
        temp = (knob1 * 10) / 1024;
        switch (temp)
        {
          case 0:  note_duration = quarter;                   break;
          case 1:  note_duration = half;                      break;
          case 2:  note_duration = whole;                     break;
          case 3:  note_duration = eighth;                    break;
          case 4:  note_duration = sixteenth;                 break;
          case 5:  note_duration = thirty_second;             break;
          case 6:  note_duration = quarter_triplet;           break;
          case 7:  note_duration = eigth_triplet;             break;
          case 8:  note_duration = sixteenth_triplet;         break;
          case 9:  note_duration = thirty_second_triplet;     break;
        }   
        break;
        
      case key_set:
        temp = (knob1 * 12) / 1024;
        switch (temp)
        {
          case 0:  base_key = c;                       break;
          case 1:  base_key = c_sharp_d_flat;          break;
          case 2:  base_key = d;                       break;
          case 3:  base_key = d_sharp_e_flat;          break;
          case 4:  base_key = e;                       break;
          case 5:  base_key = f;                       break;
          case 6:  base_key = f_sharp_g_flat;          break;
          case 7:  base_key = g;                       break;
          case 8:  base_key = g_sharp_a_flat;          break;
          case 9:  base_key = a;                       break;
          case 10:  base_key = a_sharp_b_flat;         break;
          case 11:  base_key = b;                      break;
        }
        break;
        
      case time_signature_mode:
        temp = (knob1 * 3) / 1024;
        switch (temp)
        {
          case 0:  time_signature = four_four;                       break;
          case 1:  time_signature = three_four;                      break;
          case 2:  time_signature = two_four;                        break;
        }  
        break;
  }
  
  
  // process knob 2 (note)
  note_offset = (knob2 * note_range * 12) / 1024;
  note = (base_octave * 12) + 12 + note_offset + base_key;
  
  
  // process button 3 (note send)
  buttonReading = !(digitalRead(BUTTON3));
  if ((buttonReading == true) && (button3LastReading == false))
  {
    button3 = true;
  }
  else
  {
    button3 = false;
  }
  
  button3LastReading = buttonReading;
  
  if(button3)
  {  
    switch (note_duration)
    {
      case quarter:                             break;
      case half:                         break;
      case whole:              break;
      case eighth:            break;
      case sixteenth:      break;
      case thirty_second:      break;
      case quarter_triplet:                     break;
      case eigth_triplet:                       break;
      case sixteenth_triplet:                   break;
      case thirty_second_triplet:               break;
    }
    
    long currentTime = millis();
    
    switch (note_function)
    {
        case single_note:
          addNoteToQueue(noteI, velocity, currentTime, NOTE_ON);
          addNoteToQueue(noteI, velocity, currentTime + 500, NOTE_OFF);
          break;
          
        case three_note_chord:
          addNoteToQueue(noteI, velocity, currentTime, NOTE_ON);
          addNoteToQueue(noteI, velocity, currentTime + 500, NOTE_OFF);
          
          addNoteToQueue(noteIII, velocity, currentTime, NOTE_ON);
          addNoteToQueue(noteIII, velocity, currentTime + 500, NOTE_OFF);
          
          addNoteToQueue(noteV, velocity, currentTime, NOTE_ON);
          addNoteToQueue(noteV, velocity, currentTime + 500, NOTE_OFF);
          
          /*
          Serial.print(NOTE_ON, BYTE);
          Serial.print(note, BYTE);
          Serial.print(velocity, BYTE);
          
          Serial.print(NOTE_ON, BYTE);
          Serial.print(note+4, BYTE);
          Serial.print(velocity, BYTE);
          
          Serial.print(NOTE_ON, BYTE);
          Serial.print(note+7, BYTE);
          Serial.print(velocity, BYTE);
          */
       
          break;
          
        case three_note_arpeggio:
          addNoteToQueue(noteI, velocity, currentTime, NOTE_ON);
          addNoteToQueue(noteI, velocity, currentTime + 500, NOTE_OFF);
          
          addNoteToQueue(noteIII, velocity, currentTime+50, NOTE_ON);
          addNoteToQueue(noteIII, velocity, currentTime + 550, NOTE_OFF);
          
          addNoteToQueue(noteV, velocity, currentTime+100, NOTE_ON);
          addNoteToQueue(noteV, velocity, currentTime +600, NOTE_OFF);
          
          /*
          Serial.print(NOTE_ON, BYTE);
          Serial.print(note, BYTE);
          Serial.print(velocity, BYTE);
          
          delay(500);
          
          Serial.print(NOTE_ON, BYTE);
          Serial.print(note+4, BYTE);
          Serial.print(velocity, BYTE);
          
          delay(500);
          
          Serial.print(NOTE_ON, BYTE);
          Serial.print(note+7, BYTE);
          Serial.print(velocity, BYTE);
          
          delay (500);
          */
          break;
        
          
        case three_note_random:
          /*
          for (int i = 0; i < 3; i++)
          {
            int r = random(12);
            Midi_Send(NOTE_ON, note+r, velocity);
            delay(500);
          }
          */
          break;
         
    } 
  }
  
  long currentTime = millis();
  noteEvent tempNote = noteQueue[firstNote];
  
  // if there are notes in the queue, process them.
  if (tempNote.id != 255)
  {
    // send all note events that are scheduled to occur before the current time
    while (tempNote.time < currentTime)
    {
      // send current event and remove that event from the queue
      Serial.print(tempNote.noteType);
      Serial.print(tempNote.note);
      Serial.print(tempNote.velocity);
      
      tempNote.inUse = false;
      tempNote.id = 255;
      noteQueue[tempNote.next].prev = 255;
      firstNote = tempNote.next;
      tempNote = noteQueue[tempNote.next];
    }
  }
  */

}

void updateDisplay()
{
  if ((millis() - lastDisplayUpdateTime) < displayUpdateRate)
  {
    return;
  }
  
  lcd.setCursor(0, 0);
  lcd.print(headerString);
  lcd.print(tempo);
  lcd.print("bpm");
  
  lcd.setCursor(0, 1);
  switch (control_mode)
  {
    case base_octave_mode:
      lcd.print(baseOctaveString);
      lcd.print(base_octave);
      lcd.print(spacesString);
      break;
    
    case note_range_mode:
      lcd.print(noteRangeString);
      lcd.print(note_range);
      lcd.print(spacesString);
      break;
      
    case mode_set:
      lcd.print(modeString);
      switch (mode)
      {
        case ionian:
          lcd.print ("Ionian");
          break;
          
        case dorian:
          lcd.print ("Dorian");
          break;
          
        case phrygian:
          lcd.print ("Phrygian");
          break;
          
        case lydian:
          lcd.print("Lydian");
          break;
          
        case mixolydian:
          lcd.print("Mixolydian");
          break;
          
        case aeolian:
          lcd.print("Aeolian");
          break;
          
        case locrian:
          lcd.print("Locrian");
          break;
      }
      lcd.print(spacesString);
      break; 
     
    case velocity_mode:
      lcd.print(velocityString);
      lcd.print(velocity);
      lcd.print(spacesString);
      break;
      
    case pitch_wheel:
      lcd.print(pitchBendString);
      lcd.print(pitch_bend);
      lcd.print(spacesString);
      break;
      
    case tempo_mode:
      lcd.print(tempoString);
      lcd.print(tempo);
      lcd.print("bpm");
      lcd.print(spacesString);
      break;
      
    case repeat_note:
      lcd.print(repeatString);
      switch(repeat)
      {
        case repeat_mode:
          lcd.print("Repeat");
          break;
        case no_repeat_mode:
          lcd.print("No repeat");
          break;
      }
      lcd.print(spacesString);
      break;
      
    case duration_mode:
      lcd.print(durationString);
      switch (note_duration)
      {
        case quarter:
          lcd.print("1/4");
          break;
        case half:
          lcd.print("1/2");
          break;
        case whole:
          lcd.print("whole");
          break;
        case eighth:
          lcd.print("1/8");
          break;
        case sixteenth:
          lcd.print("1/16");
          break;
        case thirty_second:
          lcd.print("1/32");
          break;
        case quarter_triplet:
          lcd.print("1/4T");
          break;
        case eigth_triplet:
          lcd.print("1/8T");
          break;
        case sixteenth_triplet:
          lcd.print("1/16T");
          break;
        case thirty_second_triplet:
          lcd.print("1/32T");
          break;
      }
      lcd.print(spacesString);
      break;
      
    case key_set:
      lcd.print(keyString);
      switch(base_key)
      {
        case c:
          lcd.print("C");
          break;
        case c_sharp_d_flat:
          lcd.print("C#/Db");
          break;
        case d:
          lcd.print("D");
          break;
        case d_sharp_e_flat:
          lcd.print("D#/Eb");
          break;
        case e:
          lcd.print("E");
          break;
        case f:
          lcd.print("F");
          break;
        case f_sharp_g_flat:
          lcd.print("F#/Gb");
          break;
        case g:
          lcd.print("G");
          break;
        case g_sharp_a_flat:
          lcd.print("G#/Ab");
          break;
        case a:
          lcd.print("A");
          break;
        case a_sharp_b_flat:
          lcd.print("A#/Bb");
          break;
        case b:
          lcd.print("B");
          break;
      }
      lcd.print(spacesString);
      break;
      
    case time_signature_mode:
      lcd.print(timeSignatureString);
      switch(time_signature)
      {
        case four_four:
          lcd.print("4/4");
          break;
        case three_four:
          lcd.print("3/4");
          break;
        case two_four:
          lcd.print("2/4");
          break;
      }
      lcd.print(spacesString);
      break;
  }
  
  lcd.setCursor(0, 2);
  lcd.print(noteFunctionString);
  switch(note_function)
  {
    case single_note:
      lcd.print("Single note");
      break;
    case three_note_chord:
      lcd.print("3-chord    ");
      break;
    case three_note_arpeggio:
      lcd.print("3-arpeggio ");
      break;
    case three_note_random:
      lcd.print("3-random   ");
      break;
  }
  //lcd.print(spacesString);
  
  lcd.setCursor(0,3);
  switch(base_key)
  {
    case c:
      lcd.print("C     ");
      break;
    case c_sharp_d_flat:
      lcd.print("C#/Db ");
      break;
    case d:
      lcd.print("D     ");
      break;
    case d_sharp_e_flat:
      lcd.print("D#/Eb ");
      break;
    case e:
      lcd.print("E     ");
      break;
    case f:
      lcd.print("F     ");
      break;
    case f_sharp_g_flat:
      lcd.print("F#/Gb ");
      break;
    case g:
      lcd.print("G     ");
      break;
    case g_sharp_a_flat:
      lcd.print("G#/Ab ");
      break;
    case a:
      lcd.print("A     ");
      break;
    case a_sharp_b_flat:
      lcd.print("A#/Bb ");
      break;
    case b:
      lcd.print("B     ");
      break;
  }
  
  switch (note_duration)
  {
    case quarter:
      lcd.print("1/4   ");
      break;
    case half:
      lcd.print("1/2   ");
      break;
    case whole:
      lcd.print("whole ");
      break;
    case eighth:
      lcd.print("1/8   ");
      break;
    case sixteenth:
      lcd.print("1/16  ");
      break;
    case thirty_second:
      lcd.print("1/32  ");
      break;
    case quarter_triplet:
      lcd.print("1/4T  ");
      break;
    case eigth_triplet:
      lcd.print("1/8T  ");
      break;
    case sixteenth_triplet:
      lcd.print("1/16T ");
      break;
    case thirty_second_triplet:
      lcd.print("1/32T ");
      break;
  }
  
  int noteOctave = (note - 12) / 12;
  int noteMod = note % 12;
  
  switch(noteMod)
  {
    case 0:
      lcd.print("C      ");
      lcd.setCursor(13,3);
      break;
    case 1:
      lcd.print("C#/Db");
      break;
    case 2:
      lcd.print("D      ");
      lcd.setCursor(13,3);
      break;
    case 3:
      lcd.print("D#/Eb");
      break;
    case 4:
      lcd.print("E      ");
      lcd.setCursor(13,3);
      break;
    case 5:
      lcd.print("F      ");
      lcd.setCursor(13,3);
      break;
    case 6:
      lcd.print("F#/Gb");
      break;
    case 7:
      lcd.print("G      ");
      lcd.setCursor(13,3);
      break;
    case 8:
      lcd.print("G#/Ab");
      break;
    case 9:
      lcd.print("A      ");
      lcd.setCursor(13,3);
      break;
    case 10:
      lcd.print("A#/Bb");
      break;
    case 11:
      lcd.print("B      ");
      lcd.setCursor(13,3);
      break;
  }
  
  lcd.print(noteOctave);

      
  lastDisplayUpdateTime = millis();
}
  

void Midi_Send(byte cmd, byte data1, byte data2) {
  Serial.print(cmd, BYTE);
  Serial.print(data1, BYTE);
  Serial.print(data2, BYTE);
}

void addNoteToQueue(scaleNotes n, int v, long t, char type)
{
  // iterate through queue to find an unallocated note.
  int i = 0;
  while (noteQueue[i].inUse == true)
  {
    i++;
  }
  
  // if queue is full, don't do anything.
  if (i == NOTE_QUEUE_LENGTH)
  {
    return;
  }
  
  // **BUGBUG note should be resolved to final value at time of encoding
  
  // found an unallocated queue member. initialize the item with current note values.
  noteQueue[i].inUse = true;
  noteQueue[i].velocity = v;
  noteQueue[i].time = t;
  noteQueue[i].noteType = NOTE_ON;
  noteQueue[i].note = n;
  noteQueue[i].id = i;
  
  // insert element into queue sorting by timestamp
  noteEvent tempNote;
  
  // if the queue already has notes in it, find where this note sits in the ordering
  if (firstNote != 255)
  {
    tempNote = noteQueue[firstNote];
    
    // if the current note happens before firstNote, then currentNote becomes the first note
    if (noteQueue[i].time < noteQueue[firstNote].time)
    {
      firstNote = i;
      noteQueue[i].prev = 255;
      noteQueue[i].next = tempNote.id;
      tempNote.prev = i;
      return;
    }
    
    // otherwise the current note slots somewhere in the queue.  look for the first note that
    // happens after the current note.
    
    while ((tempNote.time < noteQueue[i].time) && (tempNote.next != 255))
    {
      tempNote = noteQueue[tempNote.next];
    }
  
    // the current note happens before tempNote, but it might be the last note in the queue
    
    // if tempNote is the last note in the queue
    if (tempNote.next == 255)
    { 
      noteQueue[i].prev = tempNote.id;
      noteQueue[i].next = 255;
      tempNote.next = i;
    }
      
    // otherwise the current note is inserted before tempNote
    else
    {
      noteQueue[i].prev = tempNote.prev;
      noteQueue[i].next = tempNote.id;
      
      tempNote.prev = i;
      noteQueue[tempNote.prev].next = i;
    }
  }
  
  // otherwise the queue is empty and this note becomes the first member
  else
  {
    noteQueue[i].prev = 255;
    noteQueue[i].next = 255;
    firstNote = i;
  }  
}









