import re

def transcribe_audio(model, audio_path):
    """
    Transcribe audio file to text using Whisper AI.
    
    Args:
        model: Whisper model instance (loaded earlier)
        audio_path: Path to audio file (.wav, .mp3, etc.)
        
    Returns:
        Dictionary with transcription, timestamps, and segments
    """
    print("Transcribing audio...")
    
    # Call Whisper to transcribe
    result = model.transcribe(
        audio_path,
        fp16=False,                    # Don't use 16-bit precision (more accurate)
        word_timestamps=True,          # Get timestamp for EACH word
        initial_prompt=(
            "Please transcribe exactly as spoken. Include every um, uh, ah, er, pause, "
            "repetition, and false start. Do not clean up or correct the speech. "
            "Transcribe with maximum verbatim accuracy."
        )
    )
    
    return result

def process_transcription(result):
    """
    Process Whisper result to add pause markers.
    
    Args:
        result: Dictionary from Whisper with segments and word timestamps
        
    Returns:
        Tuple: (transcription_with_pauses, total_pause_duration)
    """
    transcription_with_pauses = []
    total_pause_duration = 0
    number_of_pauses = 0

    # Loop through each segment (Whisper breaks audio into segments)
    for i in range(len(result['segments'])):
        segment = result['segments'][i]
        words_in_segment = segment.get('words', [])

        # Loop through each word in this segment
        for j in range(len(words_in_segment)):
            word_info = words_in_segment[j]
            word = word_info['word']
            transcription_with_pauses.append(word)

            # Check gap to NEXT word (if not the last word)
            if j < len(words_in_segment) - 1:
                current_word_end = word_info['end']
                next_word_start = words_in_segment[j + 1]['start']
                time_gap = next_word_start - current_word_end
                
                # If gap is 1+ seconds, mark it as a pause
                if time_gap >= 1.0:
                    pause_duration = round(time_gap, 1)
                    pause_marker = f"[{pause_duration} second pause]"
                    transcription_with_pauses.append(pause_marker)
                    total_pause_duration += pause_duration
                    number_of_pauses += 1

        # Check gap between segments (if not the last segment)
        if i < len(result['segments']) - 1:
            current_segment_end = segment['end']
            next_segment_start = result['segments'][i + 1]['start']
            time_gap = next_segment_start - current_segment_end
            
            # If gap is 2+ seconds (longer threshold between segments)
            if time_gap >= 2.0:
                pause_duration = round(time_gap, 1)
                pause_marker = f"[{pause_duration} second pause]"
                transcription_with_pauses.append(pause_marker)
                total_pause_duration += pause_duration
                number_of_pauses += 1

    # Join all words and pause markers into one string
    transcription_with_pauses = ' '.join(transcription_with_pauses)
    
    # Clean up extra spaces
    transcription_with_pauses = re.sub(r'\s+', ' ', transcription_with_pauses).strip()

    return transcription_with_pauses, number_of_pauses

