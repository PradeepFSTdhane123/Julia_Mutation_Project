module JournaledSequences

using DataStructures, StringDistances

export JournaledSequence, mutate_sequence, reconstruct_sequence, is_similar, delete_position, apply_batch_mutations, list_all_mutations, find_similar_sequences

# Structure to store journaled mutations
struct JournaledSequence
    parent::Union{Nothing, JournaledSequence}  # Reference to the previous version
    changes::Dict{Int, Char}  # Dictionary: mutation position → new character
    deletions::Set{Int}  # Set to track deletions
    timestamp::Int  # Mutation timestamp
end

# Create the original sequence with no mutations
function create_original_sequence()
    return JournaledSequence(nothing, Dict(), Set(), 0)
end

# Apply a mutation at a specific position
function mutate_sequence(parent::JournaledSequence, position::Int, new_char::Char, time::Int)
    new_changes = copy(parent.changes)
    new_changes[position] = new_char
    return JournaledSequence(parent, new_changes, copy(parent.deletions), time)
end

# Delete a position in the sequence
function delete_position(parent::JournaledSequence, position::Int, time::Int)
    new_deletions = copy(parent.deletions)
    push!(new_deletions, position)
    return JournaledSequence(parent, copy(parent.changes), new_deletions, time)
end

# Apply a batch of mutations
function apply_batch_mutations(parent::JournaledSequence, mutations::Dict{Int, Char}, time::Int)
    new_changes = copy(parent.changes)
    merge!(new_changes, mutations)
    return JournaledSequence(parent, new_changes, copy(parent.deletions), time)
end

# Reconstruct the full sequence from journaled mutations
function reconstruct_sequence(base_sequence::String, journaled_seq::JournaledSequence)
    seq = collect(base_sequence)
    current = journaled_seq
    
    while current.parent !== nothing
        for (pos, char) in current.changes
            seq[pos] = char
        end
        for pos in current.deletions
            seq[pos] = '_'
        end
        current = current.parent  # Move to previous version
    end
    
    seq = filter!(!=('_'::Char), seq)  # Remove deleted positions
    return join(seq)
end

# List all mutations
function list_all_mutations(journaled_seq::JournaledSequence)
    mutations = Dict{Int, Char}()
    current = journaled_seq
    while current.parent !== nothing
        for (pos, char) in current.changes
            mutations[pos] = char
        end
        current = current.parent
    end
    return mutations
end

# Approximate search: Check if two sequences are similar
function is_similar(seq1::String, seq2::String, threshold::Float64)
    distance = evaluate(Levenshtein(), seq1, seq2)
    return distance / max(length(seq1), length(seq2)) ≤ threshold
end

# Find similar sequences in a collection
function find_similar_sequences(target_seq::String, sequences::Vector{String}, threshold::Float64)
    similar_sequences = []
    for seq in sequences
        if is_similar(target_seq, seq, threshold)
            push!(similar_sequences, seq)
        end
    end
    return similar_sequences
end

end  # End of module
