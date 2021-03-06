# operation.coffee :: Operation class for altering CTree objects

# Dependencies: none

class Operation
    constructor: (@instructions)->

    push: (i)->@instructions.push(i)
    push_list: (list)-> @push(i) for i in list

    pushinsert:(addr, pos, value)->
        @push [1, addr, pos, value]

    pushdelete:(addr, victims)->
        @push [0, addr].concat victims

    pushflatinsert:(pos, value, tree)->
        # Based on current tree state
        trace = tree.trace_index(pos)
        @pushinsert(trace.address, trace.pos, value)

    pushflatdelete:(pos, tree)->
        # Based on current tree state
        trace = tree.trace_char(pos)
        @pushdelete(trace.address, trace.pos)

    pushflatdeletes:(pos, amount, tree)->
        # Based on current tree state
        @pushflatdelete(pos+i, tree) for i in [0...amount]

    apply: (tree)->
        @apply_instruction(tree, i) for i in @instructions

    apply_instruction:(tree, i)->
        type = i[0]
        switch type
          when 0 then @apply_deletion(tree, i)
          when 1 then @apply_insertion(tree, i)

    apply_deletion:(tree, i)->
        addr = i[1]
        victims = i[2..]
        target = tree.resolve(addr)
        target.delete(pos) for pos in victims

    apply_insertion:(tree, i)->
        addr = i[1]
        pos = i[2]
        value = i[3]
        target = tree.resolve(addr)
        target.insert(pos, value)

    proto:-> {
           "type":"op",
           "instructions":@instructions,
        }

    victimize_deletions:(deletions)->
        # Turns a Tree.deletions into a set of victims for a deletion instruction
        running = -1
        result = []
        for i in [0..deletions.length]
          if not deletions[i]
            if running isnt -1
              if running is i-1
                result.push(running) 
              else
                result.push([running, i-1]) 
            running = -1
          else
            running = i if running is -1
        result

    serialize:-> JSON.stringify(@proto())

    fromTree:(address, tree)->
        # Only handles children, to support immutable root node
        # Root is assumed to be the same
        for p in [0..tree.length]
          for key, node of tree.children[p]
            nodeaddr = address.concat tree.jump(p, key)
            deletions = @victimize_deletions node.deletions
            @pushinsert address, p, node.value
            if deletions.length > 0
              @pushdelete nodeaddr, deletions
            @fromTree nodeaddr, node

this.Operation = Operation
