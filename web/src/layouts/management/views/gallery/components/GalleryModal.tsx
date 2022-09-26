import { Select, Stack, Button } from '@mantine/core';
import { TbCar } from 'react-icons/tb';
import { useAppDispatch, useAppSelector } from '../../../../../state';
import { GalleryVehicle } from '../index';
import { closeAllModals } from '@mantine/modals';
import { useState } from 'react';
import { fetchNui } from '../../../../../utils/fetchNui';

interface Props {
  setGallerySlots: React.Dispatch<React.SetStateAction<(GalleryVehicle | null)[]>>;
  index: number;
}

const GalleryModal: React.FC<Props> = ({ setGallerySlots, index }) => {
  const dispatch = useAppDispatch();
  const vehicleStock = useAppSelector((state) => state.vehicleStock);
  const vehicles = Object.entries(vehicleStock).map((vehicle) => {
    const vehicleModel = vehicle[0];
    const vehicleData = vehicle[1];
    return { label: `${vehicleData.make} ${vehicleData.name}`, value: vehicleModel };
  });
  const [selectedVehicle, setSelectedVehicle] = useState<string | null>(null);

  return (
    <Stack>
      <Select
        data={vehicles}
        icon={<TbCar size={20} />}
        searchable
        clearable
        nothingFound="No such vehicle in stock"
        value={selectedVehicle}
        onChange={(value) => setSelectedVehicle(value)}
      />
      <Button
        uppercase
        fullWidth
        variant="light"
        onClick={() => {
          closeAllModals();
          if (!selectedVehicle) return;
          setGallerySlots((prevState) => {
            return prevState.map((item, indx) => {
              if (indx === index) return { ...vehicleStock[selectedVehicle], model: selectedVehicle };
              else return item;
            });
          });
          fetchNui('galleryAddVehicle', { vehicle: selectedVehicle, slot: index + 1 });
          dispatch.vehicleStock.setVehicleInGallery({ model: selectedVehicle, gallery: true });
        }}
      >
        Confirm
      </Button>
    </Stack>
  );
};

export default GalleryModal;
