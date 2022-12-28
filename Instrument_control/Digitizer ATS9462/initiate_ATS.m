function [board_handle]=initiate_ATS()
    %load Alazar library
    if ~alazarLoadLibrary()
        fprintf('Error: ATSApi library not loaded \n');
        return
    end
    
    systemId=int32(1);
    boardId=int32 (1);  %default values for single board setup
    
    board_handle=AlazarGetBoardBySystemID(systemId,boardId);
    setdatatype(board_handle,'voidPtr',1,1);
    
    if board_handle.value==0
        fprintf('Error: Unable to open board system ID %u board ID %v \n', systemId, boardId);
    return
    end
end